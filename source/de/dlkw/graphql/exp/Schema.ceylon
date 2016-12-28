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
    type,
    typeLiteral
}
import ceylon.logging {
    Logger,
    logger
}

Logger log = logger(`module`);

shared class Schema(query, mutation)
{
    shared GQLObjectType query;
    shared GQLObjectType? mutation;

    shared ExtResult executeRequest(document, operationName=null, rootValue=null, executor=normalExecutor)
    {
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

        value result = executeSelectionSet(operationDefinition.selectionSet, rootType, rootValue, coercedVariables, errors, null, executor);
        if (is NullForError result) {
            return ExtResultImplTODO(true, null, errors);
        }
        return ExtResultImplTODO(true, result, errors);
    }

    Map<String, Result<Anything>?>|QueryError coerceVariableValues(operationDefinition, variableValues, errors)
    {
        OperationDefinition operationDefinition;
        Map<String, Anything> variableValues;
        ListMutator<QueryError> errors;

        variable [<String->Result<Anything>?>*] coercedValues = [];

        variable Boolean hasErrors = false;
        for (variableName->variableDefinition in operationDefinition.variableDefinitions) {
            if (variableValues.defines(variableName)) {
                value value_ = variableValues[variableName];
                value providedValue = variableDefinition.type.coerceInput(value_);
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
                    if (is GQLNonNullType<GQLType<Result<Anything>>, Result<Anything>> variableType = variableDefinition.type) {
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

    Map<String, Result<Anything>?>|FieldError coerceArgumentValues2(objectType, field, variableValues, errors, path)
    {
        GQLObjectType objectType;
        Field field;
        Map<String, Result<Anything>?> variableValues;

        [String, <String|Integer>*] path;
        ListMutator<FieldError> errors;

        variable [<String->Result<Anything>?>*] coercedValues = [];

        value fieldType = objectType.fields[field.name];
        assert (exists fieldType);

        variable Boolean hasErrors = false;
        for (argumentName->argumentDefinition in fieldType.arguments) {
            if (field.arguments.defines(argumentName)) {
                value value_ = field.arguments[argumentName];
                value providedValue = argumentDefinition.type.coerceInput(value_);
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
                    if (is GQLNonNullType<GQLType<Result<Anything>>, Result<Anything>> argumentType = argumentDefinition.type) {
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
            return FieldError(path);
        }
        return map(coercedValues);
    }

    GQLObjectValue? | NullForError executeSelectionSet(selectionSet, objectType, objectValue, variableValues, errors, executedPath, executor)
    {
        [Selection+] selectionSet;
        GQLObjectType objectType;
        Anything objectValue;
        Map<String, Result<Anything>?> variableValues;

        ListMutator<FieldError> errors;
        [String, <String|Integer>*]? executedPath;
        Executor executor;

        print("execute selection set ``executedPath else "null"``");

        value groupedFieldSet = collectFields(objectType, selectionSet, variableValues);

        variable Boolean hasFieldErrors = false;
        MutableMap<String, Result<Anything>?> resultMap = HashMap<String, Result<Anything>?>();

        for (responseKey->fields in groupedFieldSet) {
            String fieldName = fields.first.name;

            value fieldDefinition = objectType.fields[fieldName];
            if (is Null fieldDefinition) {
                // when can this happen?
                continue;
            }

            value pathToExecute = executedPath?.withTrailing(fieldName) else [fieldName];
            value responseValue = executeField(objectType, objectValue, fieldDefinition.type, fields, variableValues, errors, pathToExecute, executor);
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
        return GQLObjectValue(resultMap);
    }

    Map<String, [Field+]> collectFields<Value>(GQLType<Value> objectType, [Selection+] selectionSet, variableValues, MutableSet<Object>? visitedFragments=HashSet<Object>())
    {
        Map<String, Result<Anything>?> variableValues;

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

    Result<Anything>? |NullForError executeField<Value>(objectType, objectValue, fieldType, fields, variableValues, errors, path, executor)
        given Value satisfies Result<Anything>
    {
        GQLObjectType objectType;
        Anything objectValue;
        GQLType<Value> fieldType;
        [Field+] fields;
        Map<String, Result<Anything>?> variableValues;

        ListMutator<FieldError> errors;
        [String, <String|Integer>*] path;

        Executor executor;

        print("execute field ``path``");

        Field field = fields.first;

        value argumentValues = coerceArgumentValues2(objectType, field, variableValues, errors, path);
        if (is FieldError argumentValues) {
            return nothing;
        }
        value resolvedValue = resolveFieldValue(objectType, objectValue, field.name, argumentValues, errors, path);
        return completeValues(fieldType, fields, resolvedValue, variableValues, errors, path, executor);
    }

    Empty coerceArgumentValues(objectType, objectValue, variableValues)
    {
        GQLObjectType objectType;
        Anything objectValue;
        Map<String, Result<Anything>?> variableValues;
        return empty;
    }

    Anything resolveFieldValue(objectType, objectValue, fieldName, argumentValues, errors, path)
    {
        GQLObjectType objectType;
        Anything objectValue;
        String fieldName;
        Map<String, Result<Anything>?> argumentValues;

        ListMutator<FieldError> errors;
        [String, <String|Integer>*] path;

        print("resolving ``path``");

        value fieldDefinition = objectType.fields[fieldName];
        assert (exists fieldDefinition);

        if (exists resolver = fieldDefinition.resolver) {
            try {
                return resolver(objectValue, argumentValues);
            }
            catch (Throwable throwable) {
                value error = ResolvingError(path);
                errors.add(error);
                return error;
            }
        }

        if (is Null objectValue) {
            return null;
        }

        if (is Map<String, Anything> objectValue) {
            return objectValue[fieldName];
        }
        else {
            return type(objectValue).getAttribute<Nothing, Anything>(fieldName)?.bind(objectValue)?.get();
        }
    }

    Result<Anything>? | NullForError innerCompleteValues(fieldType, fields, result, variableValues, inNonNull, errors, path, executor)
    {
        GQLType<Anything> fieldType;
        [Field+] fields;
        Anything result;
        Map<String, Result<Anything>?> variableValues;

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
        case (is GQLListType<GQLType<Anything>, Anything>) {
            if (!is Iterable<Anything> result) {
                errors.add(ResolvedNotIterableError(path));
                return (inNonNull) then NullForError();
            }

            variable Boolean hasFieldErrors = false;
            MutableList<Result<Anything>?> elementResults = ArrayList<Result<Anything>?>();
            try {
                for (i->v in result.indexed) {
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
            return GQLListValue<Result<Anything>>(elementResults.sequence());
        }
        case (is GQLScalarType<Result<Anything>>) {
            return fieldType.coerceResult(result);
        }
        case (is GQLObjectType) {
            value subSelectionSet = mergeSelectionSets(fields);
            value resultObjectValue = executeSelectionSet(subSelectionSet, fieldType, result, variableValues, errors, path, executor);
            if (!inNonNull) {
                if (is NullForError resultObjectValue) {
                    return null;
                }
            }
            return resultObjectValue;
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

    Result<Anything>? |NullForError completeValues<Value>(GQLType<Value> fieldType, [Field+] fields, Anything result, variableValues, errors, [String, <String|Integer>*] path, Executor executor)
        given Value satisfies Result<Anything>
    {
        Map<String, Result<Anything>?> variableValues;

        ListMutator<FieldError> errors;

        print("complete ``path``");

        if (is GQLNonNullType<GQLType<Value>, Anything> fieldType) {
            if (is FieldError result) {
                return NullForError();
            }

            value completedResult = innerCompleteValues(fieldType.inner, fields, result, variableValues, true, errors, path, executor);
            if (is Null completedResult) {
                value error = FieldNullError(path);
                errors.add(error);
                return NullForError();
            }
            return completedResult;
        }

        value completedResult = innerCompleteValues(fieldType, fields, result, variableValues, false, errors, path, executor);
        return completedResult;
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
    shared formal GQLObjectValue? data;
    shared formal List<GQLError>? errors;
}

shared interface Result<out Value>
{
    shared formal Value value_;
}
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
class ExtResultImplTODO(includedExecution, data, errors_)
    satisfies ExtResult
{
    shared actual Boolean includedExecution;
    shared actual GQLObjectValue? data;
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
shared class FieldError(path)
    extends GQLError()
{
    shared String message => "not yet";
    shared Null locations = null;

    shared [String, <String|Integer>*] path;

    shared String stringPath => "``path.first````"".join(path.rest.map((el)=>if (is String el) then "/``el``" else "[``el.string``]"))``";
}
shared class ArgumentCoercionError(path, argumentName)
    extends FieldError(path)
{
    [String, <String|Integer>*] path;
    shared String argumentName;
}

shared class ResolvingError(path)
    extends FieldError(path)
{
    [String, <String|Integer>*] path;
}
shared class FieldNullError(path)
        extends FieldError(path)
{
    [String, <String|Integer>*] path;
}
shared class ResolvedNotIterableError(path)
        extends FieldError(path)
{
    [String, <String|Integer>*] path;
}
shared class ListCompletionError(path)
        extends FieldError(path)
{
    [String, <String|Integer>*] path;
}
class NullForError(){}
