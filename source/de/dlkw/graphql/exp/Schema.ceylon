import ceylon.collection {
    MutableMap,
    HashMap,
    MutableSet,
    HashSet,
    linked,
    MutableList,
    ArrayList,
    ListMutator
}
import ceylon.language.meta {
    type
}
import ceylon.language.meta.declaration {
    FunctionDeclaration
}
import ceylon.language.meta.model {
    Attribute,
    Class
}
import ceylon.logging {
    Logger,
    logger
}

import de.dlkw.graphql.exp.types {
    GQLObjectType,
    GQLField,
    GQLEnumType,
    GQLType,
    GQLListType,
    GQLNonNullType,
    CoercionError,
    Undefined,
    GQLAbstractObjectType,
    GQLScalarType,
    undefined,
    gqlStringType,
    ArgumentDefinition,
    GQLInterfaceType,
    GQLUnionType,
    TypeResolver,
    GQLAbstractType,
    GQLInputNonNullType,
    GQLWrapperType,
    gqlBooleanType,
    GQLTypeReference,
    resolveAllTypeReferences
}
import ceylon.random {
    DefaultRandom,
    Random
}

Logger log = logger(`package`);

shared interface TypeRegistry
{
    //shared formal void registerType(GQLType<String> type);
    shared formal GQLType<String>? lookupType(String name);
}


class IntrospectionSupport(types, queryType, mutationType, directives)
{
    shared IntrospectionSupport __schema => this;
    shared {GQLType<String>+} types;
    shared GQLObjectType queryType;
    shared GQLObjectType? mutationType;
    shared {DirectiveDefinition*} directives;
}

shared class InvalidSchemaException(String? description=null, Throwable? cause=null)
    extends Exception(description, cause)
{}


throws(`class InvalidSchemaException`)
shared class Schema(queryRoot, mutationRoot, typeResolvers = [])
    satisfies TypeRegistry
{
    "The root type for query operations."
    shared GQLObjectType queryRoot;

    "The root type for mutation operations."
    shared GQLObjectType? mutationRoot;

    // FIXME need not be publicly available
    shared {DirectiveDefinition*} directiveDefinitions= [
        DirectiveDefinition("skip", "builtin skip directive", [DirectiveLocation.field, DirectiveLocation.fragmentSpread, DirectiveLocation.inlineFragment], ["if" -> ArgumentDefinition(GQLInputNonNullType(gqlBooleanType))]),
        DirectiveDefinition("include", "builtin include directive", [DirectiveLocation.field, DirectiveLocation.fragmentSpread, DirectiveLocation.inlineFragment], ["if" -> ArgumentDefinition(GQLInputNonNullType(gqlBooleanType))])
    ];

    //#####################
    //# Type registration #
    //#####################

    "Used during setup to register all occuring types."
    MutableMap<String, GQLType<String>> types = HashMap<String, GQLType<String>>();

    "Register a type. Recursively descends into Object and wrapper types
     to register all contained named types."
    Boolean internalRegisterType(GQLType<String> type) {
        "Recursively descends into wrapper types to register the
         contained named types."
        void regWrapper(GQLWrapperType<GQLType<Anything>, Anything> type)
        {
            value inner = type.inner;
            if (is GQLWrapperType<GQLType<Anything>, Anything> inner) {
                regWrapper(inner);
            }
            else {
                assert (is GQLType<String> inner);
                internalRegisterType(inner);
            }
        }

        void regAny(GQLType<Anything> type) {
            if (is GQLWrapperType<Anything,Anything> type) {
                regWrapper(type);
            }
            else {
                assert (is GQLType<String> type);
                internalRegisterType(type);
            }
        }

        if (is GQLTypeReference type) {
            return false;
        }

        String name = type.name;

        Boolean alreadyRegistered;
        value registeredType = types[name];
        if (exists registeredType) {
            if (!type === registeredType) {
                throw InvalidSchemaException("Duplicate definition of type ``name``");
            }
            log.debug("type ``name`` already registered");
            alreadyRegistered = true;
        } else {
            log.info("registering type ``name``");
            types.put(name, type);
            alreadyRegistered = false;
        }

        if (is GQLObjectType type) {
            for (field in type.fields.items) {
                for (argumentDefinition in field.arguments) {
                    regAny(argumentDefinition.item.type);
                }
                value fieldType = field.type;
                regAny(fieldType);
            }
            for (interface_ in type.interfaces) {
                internalRegisterType(interface_);
            }
        }
        else if (is GQLUnionType type) {
            for (component in type.types) {
                internalRegisterType(component);
            }
        }

        return alreadyRegistered;
    }

    internalRegisterType(queryRoot);
    if (exists mutationRoot) {
        internalRegisterType(mutationRoot);
    }
//    resolveAllTypeReferences(queryRoot, types.mapItems((key, item) => if (is GQLObjectType item) item else null));
    resolveAllTypeReferences(queryRoot, map({ for (k->i in types) if (is GQLObjectType i) k->i }));
    internalRegisterType(introspection.typeSchema);

    GQLField introspectionFieldSchema = GQLField {
        name = "__schema";
        type = introspection.typeSchema;
    };

    GQLField introspectionFieldType = GQLField {
        name = "__type";
        type = introspection.typeType;
        arguments = map({ "name"->ArgumentDefinition<String>(GQLInputNonNullType(gqlStringType), "name of the type to query", undefined)});
        GQLType<String>? resolver(Anything introspectionSupport, Map<String, Anything> arguments)
        {
            assert (is IntrospectionSupport introspectionSupport);

            assert (is String name = arguments["name"]);
            return introspectionSupport.types.find((t) => t.name.equals(name));
        }
    };

    class GQLObjectTypeWrapper(GQLObjectType wrapped)
    extends GQLObjectType(wrapped.name, wrapped.fields.items.chain({introspectionFieldSchema, introspectionFieldType}), {}, wrapped.description)
    {
    }
    GQLObjectType query__ = GQLObjectTypeWrapper(queryRoot);

    {Element+} mkExistingFirst<Element>({Element*} elements)
    {
        return object satisfies {Element+}
        {
            iterator() => object satisfies Iterator<Element>
            {
                value internal = elements.iterator();
                next() => internal.next();
            };
        };
/*        Iterator<Element> iterator = elements.iterator();
        return {
            if (!is Finished nx = iterator.next()) then nx else nothing,
            for (el in RestIterable(iterator)) el };
*/    }

    {GQLType<String>+} registeredTypes = mkExistingFirst(types.items);
    print(registeredTypes);

    shared actual GQLType<String>? lookupType(String name)
    {
        return registeredTypes.find((t) => t.name == name);
    }

    [TypeResolver*] typeResolvers;
    for (typeResolver in typeResolvers) {
        for (knownType in typeResolver.knownTypes) {
            internalRegisterType(knownType);
        }
    }

    shared ExtResult executeRequest(document, variableValues = emptyMap, operationName=null, rootValue=object{}, inputDecoder = identity<Object>, executor=normalExecutor)
    {
        Document document;
        Map<String, Anything>? variableValues;
        String? operationName;

        Anything rootValue;

        Anything inputDecoder(Object transportValue);

        Executor executor;

        value operationDefinition = document.operationDefinition(operationName);
        if (is Null operationDefinition) {
            return ExtResultImplTODO(false, null, [
                QueryError("No matching operation found in document ``
                    if (exists operationName)
                        then "by name \"`` operationName ``\""
                        else "(need to specify name)"
                    ``.",
                    null
                )]);
        }

        value errors = ArrayList<GQLError>();
        value coercedVariables = coerceVariableValues(operationDefinition, variableValues, inputDecoder, errors);
        if (is Null coercedVariables) {
            return ExtResultImplTODO(false, null, errors);
        }

        GQLObjectType rootType;
        Executor topLevelExecutor;
        switch (operationDefinition.type)
        case (OperationType.query) {
            rootType = query__;
            topLevelExecutor = normalExecutor;
        }
        case (OperationType.mutation) {
            if (is Null mutationRoot) {
                return ExtResultImplTODO(false, null, [
                    QueryError("Mutations are not supported by the schema.", null)
                ]);
            }
            rootType = mutationRoot;
            topLevelExecutor = serialExecutor;
        }

        value result = executeSelectionSet(operationDefinition.selectionSet, rootType, rootValue, coercedVariables, document.fragmentDefinition, errors, null, executor, true);
        if (is NullForError result) {
            return ExtResultImplTODO(true, null, errors);
        }
        return ExtResultImplTODO(true, result, errors);
    }

    Map<String, Object?> | Null coerceVariableValues(operationDefinition, variableValues, inputDecoder, errors)
    {
        OperationDefinition operationDefinition;
        Map<String, Anything>? variableValues;
        Anything inputDecoder(Object transportValue);
        ListMutator<QueryError> errors;

        value varValues = variableValues else emptyMap;

        variable [<String->Object?>*] coercedValues = [];

        variable Boolean hasErrors = false;
        for (variableName->variableDefinition in operationDefinition.variableDefinitions) {
            if (varValues.defines(variableName)) {
                value transportValue = varValues[variableName];
                value inputValue = if (exists transportValue) then inputDecoder(transportValue) else null;
                value providedValue = variableDefinition.type.coerceInput(inputValue);
                if (is CoercionError providedValue) {
                    errors.add(VariableCoercionError(variableName));
                    hasErrors = true;
                    continue;
                }
                coercedValues = coercedValues.withLeading(variableName->providedValue);
            }
            else {
                value defaultValue = variableDefinition.defaultValue;
                if (is Undefined defaultValue) {
                    if (is GQLNonNullType<GQLType<Anything>, Anything> variableType = variableDefinition.type) {
                        errors.add(VariableCoercionError(variableName));
                        hasErrors = true;
                        continue;
                    }
                    // no entry in coercedValues for this variable
                }
                else {
                    coercedValues = coercedValues.withLeading(variableName->defaultValue);
                }
            }
        }
        if (hasErrors) {
            return null;
        }
        return map(coercedValues);
    }

    [Location]? singleOptionalLocation(Location? location) => if (exists location) then [location] else null;

    "Returns [[null]] to indicate some errors happened. These error(s) will already be appended
     to the [[errors]] argument then."
    Map<String, Object?> | Null coerceArgumentValues(objectType, field, variableValues, errors, path)
    {
        GQLAbstractObjectType objectType;
        Field field;
        Map<String, Object?> variableValues;

        [String, <String|Integer>*] path;
        ListMutator<FieldError> errors;

        // 1.
        variable [<String->Object?>*] coercedValues = [];

        value fieldType = objectType.fields[field.name];
        // will pass if validation was successful
        assert (exists fieldType);

        variable Boolean hasErrors = false;
        // 5., a
        for (argumentName->argumentDefinition in fieldType.arguments) {
            if (field.arguments.defines(argumentName)) {
                //d
                value value_ = field.arguments[argumentName];
                if (is Var value_) {
                    // e
                    if (variableValues.defines(value_.name)) {
                        //iii
                        coercedValues = coercedValues.withLeading(argumentName->variableValues[value_.name]);
                    }
                    else {
                        // iv
                        value defaultValue = argumentDefinition.defaultValue;
                        if (is Undefined defaultValue) {
                            if (is GQLNonNullType<GQLType<Anything>, Anything> argumentType = argumentDefinition.type) {

                                errors.add(ArgumentCoercionError(singleOptionalLocation(value_.location), path, argumentName));
                                hasErrors = true;
                            }
                            else {
                                // no entry in coercedValues for this argument
                            }
                        }
                        else {
                            coercedValues = coercedValues.withLeading(argumentName->defaultValue);
                        }
                    }
                }
                else {
                    value providedValue = argumentDefinition.type.coerceInput(value_);
                    if (is CoercionError providedValue) {
                        //g
                        // FIXME get location of value here
                        //errors.add(ArgumentCoercionError(singleOptionalLocation(value_.location), path, argumentName));
                        errors.add(ArgumentCoercionError(null, path, argumentName));
                        hasErrors = true;
                    }
                    else {
                        //h+i
                        coercedValues = coercedValues.withLeading(argumentName->providedValue);
                    }
                }
            }
            else {
                //f
                value defaultValue = argumentDefinition.defaultValue;
                if (is Undefined defaultValue) {
                    if (is GQLNonNullType<GQLType<Anything>, Anything> argumentType = argumentDefinition.type) {
                        errors.add(ArgumentCoercionError(singleOptionalLocation(field.location), path, argumentName));
                        hasErrors = true;
                        continue;
                    }
                    // no entry in coercedValues for this argument
                }
                else {
                    coercedValues = coercedValues.withLeading(argumentName->defaultValue);
                }
            }
        }
        if (hasErrors) {
            return null;
        }
        return map(coercedValues);
    }

    Map<String, Anything> | NullForError executeSelectionSet(selectionSet, objectType, objectValue, variableValues, lookupFragmentDefinition, errors, executedPath, executor, topLevel)
    {
        [Selection+] selectionSet;
        GQLAbstractObjectType objectType;
        Anything objectValue;
        Map<String, Object?> variableValues;

        FragmentDefinition? lookupFragmentDefinition(String name);
        ListMutator<FieldError> errors;
        [String, <String|Integer>*]? executedPath;
        Executor executor;

        Boolean topLevel;

        log.debug("execute selection set of object ``executedPath else "null"``");

        value groupedFieldSet = collectFields(objectType, selectionSet, variableValues, lookupFragmentDefinition);

        variable Boolean hasFieldErrors = false;
        MutableMap<String, Anything> resultMap = HashMap<String, Anything>();

        value fieldDefinitions = objectType.fields;

        for (responseKey->fields in groupedFieldSet) {
            value pathToExecute = executedPath?.withTrailing(responseKey) else [responseKey];

            // TODO start a try/catch here to convert exceptions to field errors with corresponding path

            String fieldName = fields.first.name;

            Anything usedObjectValue;
            value fieldDefinition = fieldDefinitions[fieldName];
            if (is Null fieldDefinition) {
                // when can this happen?
                continue;
            }

            if (topLevel && (fieldName == "__schema" || fieldName == "__type")) {
                usedObjectValue = IntrospectionSupport(registeredTypes, query__, mutationRoot, directiveDefinitions);
            }
            else {
                usedObjectValue = objectValue;
            }

            value responseValue = executeField(objectType, usedObjectValue, fieldDefinition.type, fields, variableValues, lookupFragmentDefinition, errors, pathToExecute, executor);
            if (is NullForError responseValue) {
                hasFieldErrors = true;
            }
            else {
                resultMap[responseKey] = responseValue;
            }
        }
        if (hasFieldErrors) {
            return nullForError;
        }
        return resultMap;
    }

    Map<String, [Field+]> collectFields(GQLAbstractObjectType objectType, [Selection+] selectionSet, variableValues, FragmentDefinition? lookupFragmentDefinition(String name), MutableSet<Object> visitedFragments=HashSet<Object>())
    {
        Map<String, Anything> variableValues;

        MutableMap<String, [Field+]> groupedFields = HashMap<String, [Field+]>(linked);
        for (selection in selectionSet) {
            if (exists skip = selection.directives?.find((dir) => dir.name == "skip")) {
                if (exists ifArg = skip.arguments?.find((arg) => arg.name == "if")) {
                    value ifValue = ifArg.value_;
                    if (is Var ifValue) {
                        value val = variableValues[ifValue.name];
                        if (is Boolean val, val) {
                            continue;
                        }
                    }
                    if (is Boolean ifValue, ifValue) {
                        continue;
                    }
                }
            }

            if (exists include_ = selection.directives?.find((dir) => dir.name == "include")) {
                if (exists ifArg = include_.arguments?.find((arg) => arg.name == "if")) {
                    value ifValue = ifArg.value_;
                    if (is Var ifValue) {
                        value val = variableValues[ifValue.name];
                        if (!is Boolean val) {
                            continue;
                        }
                        if (!val) {
                            continue;
                        }
                    }
                    if (!is Boolean ifValue) {
                        continue;
                    }
                    if (!ifValue) {
                        continue;
                    }
                }
            }

            switch (selection)
            case (is Field) {
                String responseKey = selection.responseKey;
                [Field+] groupForResponseKey;
                if (exists tmp = groupedFields[responseKey]) {
                    groupForResponseKey = tmp.withTrailing(selection);
                }
                else {
                    groupForResponseKey = [selection];
                }
                groupedFields[responseKey] = groupForResponseKey;
            }
            case (is FragmentSpread | InlineFragment) {
                Fragment fragment;
                if (is FragmentSpread selection) {
                    if (!visitedFragments.add(selection.name)) {
                        continue;
                    }
                    Fragment? fragmentDefinition = lookupFragmentDefinition(selection.name);
                    if (is Null fragmentDefinition) {
                        continue;
                    }
                    fragment = fragmentDefinition;
                }
                else {
                    fragment = selection;
                }

                if (exists fragmentTypeName = fragment.typeCondition) {
                    value fragmentType = registeredTypes.find((t)=>t.name == fragmentTypeName);
                    if (is Null fragmentType) {
                        continue;
                    }
                    if (!doesFragmentTypeApply(objectType, fragmentType)) {
                        continue;
                    }
                }

                value fragmentGroupedFieldSet = collectFields(objectType, fragment.selectionSet, variableValues, lookupFragmentDefinition, visitedFragments);

                for (responseKey -> fragmentGroup in fragmentGroupedFieldSet) {
                    [Field+] groupForResponseKey;
                    if (exists tmp = groupedFields[responseKey]) {
                        groupForResponseKey = tmp.append(fragmentGroup);
                    }
                    else {
                        groupForResponseKey = fragmentGroup;
                    }
                    groupedFields[responseKey] = groupForResponseKey;
                }
            }
        }
        return groupedFields;
    }

    Boolean doesFragmentTypeApply(GQLAbstractObjectType objectType, GQLType<String> fragmentType) {
        switch (fragmentType)
        case (is GQLObjectType) {
            return objectType.isSameTypeAs(fragmentType);
        }
        case (is GQLInterfaceType) {
            return objectType.interfaces.contains(fragmentType);
        }
        case (is GQLUnionType) {
            return fragmentType.types.contains(objectType.type);
        }
        else {
            return false;
        }
    }

    "Returns type [[Null]], [[Integer]], [[Float]], [[String]], [[Boolean]],
     or a [[List]] of these 7 types,
     or a [[Map]] mapping Strings to any of these 7 types.
     Returns [[nullForError]] if the executed field gets a null value because of error propagation
     from a field error in a non-nullable field in [[fields]]."
    Anything | NullForError executeField(objectType, objectValue, fieldType, fields, variableValues, lookupFragmentDefinition, errors, path, executor)
    {
        GQLAbstractObjectType objectType;
        Anything objectValue;
        GQLType<String?> fieldType;
        [Field+] fields;
        Map<String, Object?> variableValues;

        FragmentDefinition? lookupFragmentDefinition(String name);
        ListMutator<FieldError> errors;
        [String, <String|Integer>*] path;

        Executor executor;

        log.debug("execute field ``path``");

        Field field = fields.first;

        value argumentValues = coerceArgumentValues(objectType, field, variableValues, errors, path);
        if (is Null argumentValues) {
            return null;
        }
        value resolvedValue = resolveFieldValue(objectType, objectValue, field.name, argumentValues, errors, path, field.location);
        // a field error from resolution will be converted to null or propagated up by the completeValues call
        return completeValues(fieldType, fields, resolvedValue, variableValues, lookupFragmentDefinition, errors, path, field.location, executor);
    }

    Anything | ResolutionError resolveFieldValue(objectType, objectValue, fieldName, argumentValues, errors, path, fieldLocation)
    {
        GQLAbstractObjectType objectType;
        Anything objectValue;
        String fieldName;
        Map<String, Object?> argumentValues;

        ListMutator<FieldError> errors;
        [String, <String|Integer>*] path;

        Location? fieldLocation;

        log.debug("resolving ``path``");

        // FIXME/TODO: move this after exists resolver to make resolver work even if no (root) object is given?
        if (is Null objectValue) {
            return null;
        }

        value fieldDefinition = objectType.fields[fieldName];
        // will pass if validation was successful
        assert (exists fieldDefinition);

        if (exists resolver = fieldDefinition.resolver) {
            try {
                return resolver(objectValue, argumentValues);
            }
            catch (Throwable throwable) {
                log.error("err: ", throwable);
                value error = ResolutionError(singleOptionalLocation(fieldLocation), path);
                errors.add(error);
                return error;
            }
        }

        if (is Map<String, Anything> objectValue) {
            return objectValue[fieldName];
        }
        else {
            return getDyn(objectValue, fieldName);
        }
    }

    Anything | NullForError completeValues(fieldType, fields, result, variableValues, lookupFragmentDefinition, errors, path, Location? fieldLocation, executor)
    {
        GQLType<String?> fieldType;
        [Field+] fields;
        Anything result;
        Map<String, Object?> variableValues;

        FragmentDefinition? lookupFragmentDefinition(String name);
        ListMutator<FieldError> errors;
        [String, <String|Integer>*] path;

        Executor executor;

        log.debug("complete ``path``");

        if (is GQLNonNullType<GQLType<String?>, Anything> fieldType) {
            if (is FieldError result) {
                return nullForError;
            }

            value completedResult = innerCompleteValues(fieldType.inner, fields, result, variableValues, lookupFragmentDefinition, true, errors, path, fieldLocation, executor);
            if (!is NullForError completedResult, is Null v = completedResult) {
                log.error("resolved a null value for non-null typed field ``path``");
                value error = FieldNullError(singleOptionalLocation(fieldLocation), path);
                errors.add(error);
                return nullForError;
            }
            return completedResult;
        }

        value completedResult = innerCompleteValues(fieldType, fields, result, variableValues, lookupFragmentDefinition, false, errors, path, fieldLocation, executor);
        return completedResult;
    }

    Anything | NullForError innerCompleteValues(fieldType, fields, result, variableValues, lookupFragmentDefinition, inNonNull, errors, path, Location? fieldLocation, executor)
    {
        GQLType<String?> fieldType;
        [Field+] fields;
        Anything result;
        Map<String, Object?> variableValues;

        FragmentDefinition? lookupFragmentDefinition(String name);
        Boolean inNonNull;

        ListMutator<FieldError> errors;
        [String, <String|Integer>*] path;
        Executor executor;

        if (is Null result) {
            return result;
        }
        if (is FieldError result) {
            return (inNonNull) then nullForError;
        }

        Random random = DefaultRandom();
        Anything | NullForError raiseInternalError(String message, [Location+]? locations, Throwable? cause=null)
        {
            value code = random.nextInteger(#1000000000000);
            value tmp = ("000000000000" + Integer.format(code, 16));
            value stringCode = tmp[tmp.size-12:12];
            log.error(message, cause);
            errors.add(FieldError("internal error (log code ``stringCode``)", locations, path));
            return (inNonNull) then nullForError;
        }

        switch (fieldType)
        case (is GQLListType<GQLType<String?>, Anything>) {
            if (!is Iterable<Anything> result) {
                errors.add(ResolvedNotIterableError(singleOptionalLocation(fieldLocation), path));
                return (inNonNull) then nullForError;
            }

            // for convenience, use items of a map as list entries.
            // may not be what is desired if items don't contain the map keys.
//            {Anything*} iterable = if (is Map<Anything, Anything> result) then result.items else result;
            value iterable = result;

            variable Boolean hasFieldErrors = false;
            MutableList<Anything> elementResults = ArrayList<Anything>();

            // need to do weird loop to have access to index when iterating to the
            // next item yields an exception.

            variable Integer idx = -1;
            value iterator = iterable.iterator();
            while (true) {
                ++idx;

                Anything v;
                try {
                    v = iterator.next();
                }
                catch (Throwable t) {
                    log.error("error iterating Iterable while creating GQLListValue", t);
                    errors.add(ListCompletionError(if (exists fieldLocation) then [fieldLocation] else null, path.withTrailing(idx)));
                    hasFieldErrors = true;
                    continue;
                }

                if (is Finished v) {
                    break;
                }

                value elementResult = completeValues(fieldType.inner, fields, v, variableValues, lookupFragmentDefinition, errors, path.withTrailing(idx), fieldLocation, executor);
                if (is NullForError elementResult) {
                    hasFieldErrors = true;
                } else {
                    elementResults.add(elementResult);
                }
            }

            if (hasFieldErrors) {
                return (inNonNull) then nullForError;
            }
            return elementResults.sequence();
        }
        case (is GQLScalarType<Anything, Nothing> | GQLEnumType<Anything>) {
            value coerced = fieldType.coerceResult(result);
            if (is CoercionError coerced) {
                errors.add(ResultCoercionError(singleOptionalLocation(fieldLocation), path, coerced));
                return (inNonNull) then nullForError;
            }
            return coerced;
        }
        case (is GQLAbstractObjectType | GQLInterfaceType | GQLUnionType) {
            GQLAbstractObjectType objectType;
            if (is GQLAbstractObjectType fieldType) {
                objectType = fieldType;
            }
            else {
                value resolvedAbstractType = resolveAbstractType(fieldType, result);
                if (is AbstractTypeResolutionError resolvedAbstractType) {
                    value errMsg = if (exists message = resolvedAbstractType.message)
                        then "Error resolving concrete type for ``result`` as ``fieldType.kind`` ``fieldType.name``: ``message``"
                        else "Error resolving concrete type for ``result`` as ``fieldType.kind`` ``fieldType.name``";
                    return raiseInternalError(errMsg, singleOptionalLocation(fieldLocation), resolvedAbstractType.cause);
                }
                objectType = resolvedAbstractType;
            }
            try {
                value subSelectionSet = mergeSelectionSets(fields);
                value resultObjectValue = executeSelectionSet(subSelectionSet, objectType, result, variableValues, lookupFragmentDefinition, errors, path, executor, false);
                if (!inNonNull) {
                    if (is NullForError resultObjectValue) {
                        return null;
                    }
                }
                return resultObjectValue;
            }
            catch (Throwable t) {
                return raiseInternalError("error completing object", singleOptionalLocation(fieldLocation), t);
            }
        }
        else {
            return raiseInternalError("unexpected field type ``fieldType.string``", singleOptionalLocation(fieldLocation));
        }
    }

    class AbstractTypeResolutionError(shared String? message=null, shared Throwable? cause=null){}

    GQLObjectType | AbstractTypeResolutionError resolveAbstractType(GQLAbstractType abstractType, Object objectValue)
    {
        String? resolvedTypeName;
        try {
            resolvedTypeName = typeResolvers
                .map((typeResolver) => typeResolver.resolveAbstractType(abstractType, objectValue))
                .coalesced
                .first;
        }
        catch (Exception t) {
            return AbstractTypeResolutionError("Exception calling type resolver", t);
        }

        if (is Null resolvedTypeName) {
            return AbstractTypeResolutionError();
        }

        value resolvedType = lookupType(resolvedTypeName);
        if (!is GQLObjectType resolvedType) {
            return AbstractTypeResolutionError("Resolved abstract type to type ``resolvedTypeName`` which is non-Object or not registered.");
        }

        if (is GQLInterfaceType abstractType) {
            if (!resolvedType.interfaces.contains(abstractType)) {
                return AbstractTypeResolutionError("Resolved type ``resolvedType.name`` does not implement interface ``abstractType.name``");
            }
        }
        else {
            if (abstractType.types.contains(resolvedType)) {
                return AbstractTypeResolutionError("Resolved type ``resolvedType.name`` does not occur in union ``abstractType.name``");
            }
        }
        return resolvedType;
    }

    [Selection+] mergeSelectionSets([Field+] fields)
    {
        value merged = fields.flatMap((field) => field.selectionSet else []).sequence();
        if (is Empty merged) {
            throw AssertionError("No fields in merged selection set (was no validation done?)");
        }
        return merged;
    }
}

shared interface Executor {
    shared formal Future<Result> execute<Result>(Result() callable);
}

shared interface Future<Result>
{
    shared formal Result get(Result() callable);
}

object serialExecutor
    satisfies Executor
{
    shared actual Future<Result> execute<Result>(Result callable())
    {
        Result result = callable();
        object noFuture satisfies Future<Result>
        {
            shared actual Result get(Result() callable) => result;
        }
        return noFuture;
    }
}

// TODO: use a async/concurrent executor once there is something available
Executor normalExecutor = serialExecutor;

shared interface ExtResult
{
    shared formal Boolean includedExecution;
    shared formal Map<String, Anything>? data;
    shared formal List<GQLError>? errors;
}

shared class XResult<out Value>(value_)
{
    shared Value value_;
}
/*
shared class GQLIntValue(Integer value__)
    satisfies Result<Integer>
{
    if (value__ >= 2 ^ 31) {
        throw OverflowException("could not coerce positive Integer to 32 bit");
    }
    if (value__ < -(2 ^ 31)) {
        throw OverflowException("could not coerce negative Integer to 32 bit");
    }
    shared actual Integer value_=>value__;
}

shared class GQLStringValue(shared String value__)
    satisfies Result<String>
{
    shared actual String value_=>value__;
}

shared class GQLBooleanValue(shared Boolean value__)
    satisfies Result<Boolean>
{
    shared actual Boolean value_ => value__;
}

shared class GQLObjectValue(shared Map<String, Result<Anything>?> value__)
    satisfies Result<Map<String, Result<Anything>?>>
{
    shared actual Map<String, Result<Anything>?> value_=>value__;
}
shared class GQLListValue<out Value>(shared Value?[] elements)
    satisfies Result<Value?[]>
    given Value satisfies Result<Anything>
{
    shared actual Value?[] value_=>elements;
}
*/
class ExtResultImplTODO(includedExecution, data, errors_)
    satisfies ExtResult
{
    shared actual Boolean includedExecution;
    shared actual Map<String, Anything>? data;
    List<GQLError> errors_;
    shared actual List<GQLError>? errors = if (errors_.empty) then null else errors_;

// TODO what is a result
}

class ExecutedPath(first, pathComponent=[])
{
    String first;
    PathComponent[] pathComponent;
}

class PathComponent()
{

}

shared class VariableCoercionError(shared String variableName)
    extends QueryError("Could not coerce variable ``variableName``", null)
{}
shared class FieldError(message, locations, path)
    extends GQLError(message, locations)
{
    String message;
    [Location+]? locations;

    shared [String, <String|Integer>*] path;

    shared String stringPath => "``path.first````"".join(path.rest.map((el)=>if (is String el) then "/``el``" else "[``el.string``]"))``";
}
shared class ArgumentCoercionError([Location+]? locations, path, argumentName)
    extends FieldError("argument coercion", locations, path) //TODO
{
    [String, <String|Integer>*] path;
    shared String argumentName;
}

shared class ResultCoercionError([Location+]? locations, path, CoercionError coercionError)
    extends FieldError("Result coercion: ``coercionError.message``", locations, path)
{
    [String, <String|Integer>*] path;
}

shared class ResolutionError([Location+]? locations, path)
    extends FieldError("Could not resolve field", locations, path)
{
    [String, <String|Integer>*] path;
}
shared class FieldNullError([Location+]? locations, path)
        extends FieldError("Resolved null value for NON_NULL field", locations, path)
{
    [String, <String|Integer>*] path;
}
shared class ResolvedNotIterableError([Location+]? locations, path)
        extends FieldError("Resolved value for LIST field is not an Iterable", locations, path)
{
    [String, <String|Integer>*] path;
}
shared class ListCompletionError([Location+]? locations, path)
        extends FieldError("Exception while iterating over Iterable for LIST field", locations, path)
{
    [String, <String|Integer>*] path;
}

abstract class NullForError() of nullForError{}
object nullForError extends NullForError(){}

class RestIterable<Element>(Iterator<Element> startedIterator)
        satisfies {Element*}
{
    iterator() => object satisfies Iterator<Element>
    {
        next() => startedIterator.next();
    };
}

FunctionDeclaration getAssertedDeclaration(String memberName)
{
    value declaration = `interface Class`.getMemberDeclaration<FunctionDeclaration>(memberName);
    assert (exists declaration);
    return declaration;
}

FunctionDeclaration declarationOfGetAttribute = getAssertedDeclaration("getAttribute");

Anything getDyn(Object obj, String name)
{
    value t = type(obj);
    value methodGetAttribute = declarationOfGetAttribute.memberApply<Nothing, Attribute<>?, [String]>(type(t), t);
    value getAttribute = methodGetAttribute.bind(t);

    value attribute = getAttribute(name);
    if (is Null attribute) {
        // TODO make configurable: silent null / log message / exception (field error)
        log.warn("Cannot resolve value: No attribute \"``name``\" found in object of type ``type(obj)``.");
        return null;
    }
    value val = attribute.bind(obj);
    value result = val.get();
    return result;
}

shared void r()
{
    class A()
    {
        shared Integer a=5;
        Integer b=6;
    }
    class B() extends A()
    {
        shared Float c = 5.4;
    }
    value x = getDyn(B(), "b");
    print(x);
}
