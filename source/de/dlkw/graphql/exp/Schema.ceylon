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
import ceylon.logging {
    Logger,
    logger
}
import ceylon.language.meta.declaration {
    FunctionDeclaration
}
import ceylon.language.meta.model {
    Attribute,
    Type,
    Class
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
    GQLTypeReference,
    resolveAllTypeReferences,
    undefined,
    gqlStringType,
    ArgumentDefinition,
    gqlBooleanType,
    InputCoercing,
    GQLInpNonNullType,
    GQLNullableType,
    GQLInterfaceType,
    GQLUnionType,
    TypeResolver,
    GQLAbstractType
}

Logger log = logger(`package`);

shared class Schema(query_, mutation)
{
    GQLObjectType query_;
    shared GQLObjectType? mutation;


    GQLField<Nothing> introspectionFieldSchema = GQLField {
        name = "__schema";
        type = introspection.typeSchema;
    };

    GQLField<Nothing> introspectionFieldType = GQLField {
        name = "__type";
        type = introspection.typeType;
        arguments = map({ "name"->ArgumentDefinition<String>(GQLInpNonNullType<GQLNullableType&InputCoercing<String, String>, String, String>(gqlStringType), undefined)});
        GQLType? resolver(Anything introspectionSupport, Map<String, Anything> arguments)
        {
            assert (is IntrospectionSupport introspectionSupport);

            assert (is String name = arguments["name"]);
            return introspectionSupport.types.find((t) =>
            t.name?.equals(name) else false);
        }
    };
    Map<String, TypeResolver> typeResolvers = emptyMap;
    TypeResolver unspecificTypeResolver = object satisfies TypeResolver{
        shared actual GQLType resolveAbstractType(GQLAbstractType abstractType, Object objectValue) => nothing;

    };

    class GQLObjectTypeWrapper(GQLObjectType wrapped)
    extends GQLObjectType(wrapped.name, wrapped.fields.items.chain({introspectionFieldSchema, introspectionFieldType}), {}, wrapped.description)
    {
    }
    shared GQLObjectType query = GQLObjectTypeWrapper(query_);

    MutableMap<String, GQLObjectType | GQLEnumType> types = HashMap<String, GQLObjectType | GQLEnumType>();
    {GQLObjectType*} allIntrospectionTypes = {
        introspection.typeSchema
        ,
        introspection.typeType
    };

    void internalRegisterType(GQLObjectType | GQLEnumType type)
    {
        assert (exists tName = type.name); // FIXME should be necessary
        log.info("registering type ``tName``");
        if (tName.startsWith("__")) {
            throw; // TODO
        }

        value registeredType = types[tName];
        if (exists registeredType) {
            if (!type === registeredType) {
                throw ; // TODO
            }
        }
        else {
            types.put(tName, type);
        }

        if (is GQLObjectType type) {
            for (field in type.fields.items) {
                if (is GQLObjectType | GQLEnumType fieldType = field.type) {
                    internalRegisterType(fieldType);
                }
            }
        }
    }

    internalRegisterType(query_);

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

    {GQLType+} registeredTypes = mkExistingFirst(types.items);
    print(registeredTypes);

    shared void registerType(GQLObjectType | GQLEnumType type)
    {
        internalRegisterType(type);
    }

    shared ExtResult executeRequest(document, operationName=null, rootValue=object{}, executor=normalExecutor)
    {
        print(allIntrospectionTypes);
        print(types);
        Document document;
        String? operationName;

        Anything rootValue;

        Executor executor;

        value operationDefinition = document.operationDefinition(operationName);
        if (is Null operationDefinition) {
            throw AssertionError("No matching operation found ``
                if (exists operationName)
                    then "by name \"`` operationName ``\""
                    else "(need to specify name)"
                ``.");
        }

        value errors = ArrayList<GQLError>();
        value coercedVariables = coerceVariableValues(operationDefinition, map([]), errors);
        if (is QueryError coercedVariables) {
            return ExtResultImplTODO(false, null, errors);
        }

        GQLObjectType rootType;
        Executor topLevelExecutor;
        switch (operationDefinition.type)
        case (OperationType.query) {
            rootType = query;
            topLevelExecutor = normalExecutor;
        }
        case (OperationType.mutation) {
            if (is Null mutation) {
                throw AssertionError("Mutations are not supported.");
            }
            rootType = mutation;
            topLevelExecutor = serialExecutor;
        }

        value result = executeSelectionSet(operationDefinition.selectionSet, rootType, rootValue, coercedVariables, errors, null, executor, true);
        if (is NullForError result) {
            return ExtResultImplTODO(true, null, errors);
        }
        return ExtResultImplTODO(true, result, errors);
    }

    Map<String, Anything> | QueryError coerceVariableValues(operationDefinition, variableValues, errors)
    {
        OperationDefinition operationDefinition;
        Map<String, Anything> variableValues;
        ListMutator<QueryError> errors;

        variable [<String->Anything>*] coercedValues = [];

        variable Boolean hasErrors = false;
        for (variableName->variableDefinition in operationDefinition.variableDefinitions) {
            if (variableValues.defines(variableName)) {
                value value_ = variableValues[variableName];
                value providedValue = variableDefinition.type.ddCI(value_);
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
                    if (is GQLNonNullType<GQLType> variableType = variableDefinition.type) {
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
            return QueryError();
        }
        return map(coercedValues);
    }

    Map<String, Anything> | FieldError coerceArgumentValues2(objectType, field, variableValues, errors, path)
    {
        GQLAbstractObjectType objectType;
        Field field;
        Map<String, Anything> variableValues;

        [String, <String|Integer>*] path;
        ListMutator<FieldError> errors;

        variable [<String->Anything>*] coercedValues = [];

        value fieldType = objectType.fields[field.name];
        assert (exists fieldType);

        variable Boolean hasErrors = false;
        for (argumentName->argumentDefinition in fieldType.arguments) {
            if (field.arguments.defines(argumentName)) {
                value value_ = field.arguments[argumentName];
                value providedValue = argumentDefinition.type.ddCI(value_);
                if (is CoercionError providedValue) {
                    errors.add(ArgumentCoercionError(path, argumentName));
                    hasErrors = true;
                    continue;
                }
                coercedValues = coercedValues.withLeading(argumentName->providedValue);
            }
            else {
                value defaultValue = argumentDefinition.defaultValue;
                if (is Undefined defaultValue) {
                    if (is GQLNonNullType<GQLType> argumentType = argumentDefinition.type) {
                        errors.add(ArgumentCoercionError(path, argumentName));
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
            return FieldError("could not coerce arguments", path);
        }
        return map(coercedValues);
    }

    Map<String, Anything> | NullForError executeSelectionSet(selectionSet, objectType, objectValue, variableValues, errors, executedPath, executor, topLevel)
    {
        [Selection+] selectionSet;
        GQLAbstractObjectType objectType;
        Anything objectValue;
        Map<String, Anything> variableValues;

        ListMutator<FieldError> errors;
        [String, <String|Integer>*]? executedPath;
        Executor executor;

        Boolean topLevel;

        log.debug("execute selection set of object ``executedPath else "null"``");

        value groupedFieldSet = collectFields(objectType, selectionSet, variableValues);

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
                usedObjectValue = IntrospectionSupport(registeredTypes, query, mutation, []);
            }
            else {
                usedObjectValue = objectValue;
            }

            value responseValue = executeField(objectType, usedObjectValue, fieldDefinition.type, fields, variableValues, errors, pathToExecute, executor);
            if (is NullForError responseValue) {
                hasFieldErrors = true;
            }
            else {
                resultMap[responseKey] = responseValue;
            }
        }
        if (hasFieldErrors) {
            return NullForError();
        }
        return resultMap;
    }

    Map<String, [Field+]> collectFields(GQLAbstractObjectType objectType, [Selection+] selectionSet, variableValues, MutableSet<Object>? visitedFragments=HashSet<Object>())
    {
        Map<String, Anything> variableValues;

        MutableMap<String, [Field+]> groupedFields = HashMap<String, [Field+]>(linked);
        for (selection in selectionSet) {
            // TODO 3a @skip directive
            // TODO 3b @include directive

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
            case (is FragmentSpread) {
                throw AssertionError("not implemented yet");
            }
            case (is InlineFragment) {
                throw AssertionError("not implemented yet");
            }
        }
        return groupedFields;
    }

    "Returns type [[Null]], [[Integer]], [[Float]], [[String]], [[Boolean]],
     or a [[List]] of these 7 types,
     or a [[Map]] mapping Strings to any of these 7 types.
     Returns [[NullForError]] if the executed field gets a null value because of error propagation
     from a field error in a non-nullable field in [[fields]]."
    Anything | NullForError executeField(objectType, objectValue, fieldType, fields, variableValues, errors, path, executor)
    {
        GQLAbstractObjectType objectType;
        Anything objectValue;
        GQLType fieldType;
        [Field+] fields;
        Map<String, Anything> variableValues;

        ListMutator<FieldError> errors;
        [String, <String|Integer>*] path;

        Executor executor;

        log.debug("execute field ``path``");

        Field field = fields.first;

        value argumentValues = coerceArgumentValues2(objectType, field, variableValues, errors, path);
        if (is FieldError argumentValues) {
            return null;
        }
        value resolvedValue = resolveFieldValue(objectType, objectValue, field.name, argumentValues, errors, path);
        // a field error from resolution will be converted to null or propagated up by the completeValues call
        return completeValues(fieldType, fields, resolvedValue, variableValues, errors, path, executor);
    }

    Anything | ResolvingError resolveFieldValue(objectType, objectValue, fieldName, argumentValues, errors, path)
    {
        GQLAbstractObjectType objectType;
        Anything objectValue;
        String fieldName;
        Map<String, Anything> argumentValues;

        ListMutator<FieldError> errors;
        [String, <String|Integer>*] path;

        log.debug("resolving ``path``");

        // FIXME/TODO: move this after exists resolver to make resolver work even if no (root) object is given?
        if (is Null objectValue) {
            return null;
        }

        value fieldDefinition = objectType.fields[fieldName];
        assert (exists fieldDefinition);

        if (exists resolver = fieldDefinition.resolver) {
            try {
                return resolver(objectValue, argumentValues);
            }
            catch (Throwable throwable) {
                log.error("err: ", throwable);
                value error = ResolvingError(path);
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

    Anything | NullForError completeValues(fieldType, fields, result, variableValues, errors, path, executor)
    {
        GQLType fieldType;
        [Field+] fields;
        Anything result;
        Map<String, Anything> variableValues;

        ListMutator<FieldError> errors;
        [String, <String|Integer>*] path;

        Executor executor;

        log.debug("complete ``path``");

        if (is GQLNonNullType<GQLType> fieldType) {
            if (is FieldError result) {
                return NullForError();
            }

            value completedResult = innerCompleteValues(fieldType.inner, fields, result, variableValues, true, errors, path, executor);
            if (!is NullForError completedResult, is Null v = completedResult) {
                log.error("resolved a null value for non-null typed field ``path``");
                value error = FieldNullError(path);
                errors.add(error);
                return NullForError();
            }
            return completedResult;
        }

        value completedResult = innerCompleteValues(fieldType, fields, result, variableValues, false, errors, path, executor);
        return completedResult;
    }

    Anything | NullForError innerCompleteValues(fieldType, fields, result, variableValues, inNonNull, errors, path, executor)
    {
        GQLType fieldType;
        [Field+] fields;
        Anything result;
        Map<String, Anything> variableValues;

        Boolean inNonNull;

        ListMutator<FieldError> errors;
        [String, <String|Integer>*] path;
        Executor executor;

        if (is Null result) {
            return result;
        }
        if (is FieldError result) {
            return (inNonNull) then NullForError();
        }

        switch (fieldType)
        case (is GQLListType<GQLType>) {
            if (!is Iterable<Anything> result) {
                errors.add(ResolvedNotIterableError(path));
                return (inNonNull) then NullForError();
            }

            // for convenience, use items of a map as list entries.
            // may not be what is desired if items don't contain the map keys.
            {Anything*} iterable = if (is Map<Anything, Anything> result) then result.items else result;

            variable Boolean hasFieldErrors = false;
            MutableList<Anything> elementResults = ArrayList<Anything>();
            try {
                for (i->v in iterable.indexed) {
                    value elementResult = completeValues(fieldType.inner, fields, v, variableValues, errors, path.withTrailing(i), executor);
                    if (is NullForError elementResult) {
                        hasFieldErrors = true;
                    } else {
                        elementResults.add(elementResult);
                    }
                }
            }
            catch (Throwable t) {
                log.error("error iterating Iterable while creating GQLListValue", t);
                errors.add(ListCompletionError(path));
                return (inNonNull) then NullForError();
            }
            if (hasFieldErrors) {
                return (inNonNull) then NullForError();
            }
            return elementResults.sequence();
        }
        case (is GQLScalarType<Anything, Nothing> | GQLEnumType) {
            return fieldType.coerceResult(result);
        }
        case (is GQLAbstractObjectType | GQLInterfaceType | GQLUnionType) {
            GQLAbstractObjectType objectType;
            if (is GQLAbstractObjectType fieldType) {
                objectType = fieldType;
            }
            else {
                objectType = resolveAbstractType(fieldType, result);
            }
            try {
                value subSelectionSet = mergeSelectionSets(fields);
                value resultObjectValue = executeSelectionSet(subSelectionSet, objectType, result, variableValues, errors, path, executor, false);
                if (!inNonNull) {
                    if (is NullForError resultObjectValue) {
                        return null;
                    }
                }
                return resultObjectValue;
            }
            catch (Throwable t) {
                log.error("error completing object", t);
                errors.add(FieldError("internal error", path));
                return (inNonNull) then NullForError();
            }
        }
        /*
        case (is GQLInterfaceType | GQLUnionType) {
            GQLObjectType objectType = resolveAbstractType(fieldType, result);
            return a(fields, objectType, result);
        }
        */
        else {
            throw AssertionError(fieldType.string);
        }
    }

    GQLObjectType resolveAbstractType(GQLAbstractType abstractType, Object objectValue)
    {
        GQLType? resolvedType;
        if (exists typeResolver = typeResolvers[abstractType.name]) {
            resolvedType = typeResolver.resolveAbstractType(abstractType, objectValue);
        }
        else {
            resolvedType = unspecificTypeResolver.resolveAbstractType(abstractType, objectValue);
        }

        if (is Null resolvedType) {
            throw AssertionError("could not determine concrete type for ``objectValue`` as ``""/*abstractType.kind*/ `` ``abstractType.name``"); // TODO
        }

        if (!is GQLObjectType resolvedType) {
            throw; // TODO
        }
        if (is GQLInterfaceType abstractType) {
            if (!resolvedType.interfaces.contains(abstractType)) {
                throw AssertionError("type ``resolvedType.name`` does not implement interface ``abstractType.name``"); // TODO
            }
        }
        else {
            if (abstractType.types.contains(resolvedType)) {
                throw AssertionError("type ``resolvedType.name`` does not occur in union ``abstractType.name``"); // TODO
            }
        }
        return resolvedType;
    }

    /*
    GQLObjectType<Anything> resolveAbstractType(GQLInterfaceType | GQLUnionType fieldType, Anything result)
    {
        return nothing;
    }
    */

    [Selection+] mergeSelectionSets([Field+] fields)
    {
        variable [Selection*] x = [];
        for (field in fields) {
            value fss = field.selectionSet;
            if (is Null fss) {
                print("***check me! selectionset null");
                continue;
            }
            x = x.append(fss);
        }
        value y = fields.flatMap((field) => field.selectionSet else []);
        assert(y.sequence() == x.sequence());
        assert (nonempty yy = y.sequence());
        return yy;
    }

    class IntrospectionSupport(types, queryType, mutationType, directives)
    {
        shared IntrospectionSupport __schema => this;
        shared {GQLType+} types;
        shared GQLObjectType queryType;
        shared GQLObjectType? mutationType;
        shared Empty directives;
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
    extends QueryError()
{}
shared class FieldError(message, path)
    extends GQLError()
{
    shared String message;
    shared Null locations = null;

    shared [String, <String|Integer>*] path;

    shared String stringPath => "``path.first````"".join(path.rest.map((el)=>if (is String el) then "/``el``" else "[``el.string``]"))``";
}
shared class ArgumentCoercionError(path, argumentName)
    extends FieldError("argument coercion", path) //TODO
{
    [String, <String|Integer>*] path;
    shared String argumentName;
}

shared class ResolvingError(path)
    extends FieldError("resolving", path)//TODO
{
    [String, <String|Integer>*] path;
}
shared class FieldNullError(path)
        extends FieldError("null", path)//TODO
{
    [String, <String|Integer>*] path;
}
shared class ResolvedNotIterableError(path)
        extends FieldError("not iterable", path)//TODO
{
    [String, <String|Integer>*] path;
}
shared class ListCompletionError(path)
        extends FieldError("complete list", path)//TODO
{
    [String, <String|Integer>*] path;
}
class NullForError(){}

class RestIterable<Element>(Iterator<Element> startedIterator)
        satisfies {Element*}
{
    iterator() => object satisfies Iterator<Element>
    {
        next() => startedIterator.next();
    };
}


Anything getDyn(Object obj, String name)
{
    // could be moved outside this function and evaluated only once
    value declGetAttribute = `interface Class`.getMemberDeclaration<FunctionDeclaration>("getAttribute");
    assert (exists declGetAttribute);

    value t = type(obj);
    value methodGetAttribute = declGetAttribute.memberApply<Nothing, Attribute<>?, [String]>(type(t), t);
    value getAttribute = methodGetAttribute.bind(t);

    value attribute = getAttribute(name);
    if (is Null attribute) {
        // TODO make configurable: silent null / log message / exception (field error)
        log.warn("Cannot resolve value: No attribute ``name`` found in object of type ``type(obj)``.");
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
    value x = getDyn(B(), "c");
    print(x);
}