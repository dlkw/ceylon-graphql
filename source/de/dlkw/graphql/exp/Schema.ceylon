import ceylon.collection {
    MutableMap,
    HashMap,
    MutableSet,
    HashSet,
    linked,
    MutableList,
    ArrayList
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

    shared ExtResult execute(document, operationName=null, rootValue=null, executor=normalExecutor)
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

        // TODO: coerce variable values

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

        value errors = ArrayList<FieldError>();
        value result = executeSelectionSet(operationDefinition.selectionSet, rootType, rootValue, [], errors, null, executor);
        if (is NullForError result) {
            return ExtResultImplTODO(true, null, errors);
        }
        return ExtResultImplTODO(true, result, errors);
    }

    GQLObjectValue? |NullForError executeSelectionSet(selectionSet, objectType, objectValue, variableValues, errors, executedPath, executor)
    {
        [Selection+] selectionSet;
        GQLObjectType objectType;
        Anything objectValue;
        Empty variableValues;

        MutableList<FieldError> errors;
        [String, <String|Integer>*]? executedPath;
        Executor executor;

        print("execute selection set ``executedPath else "null"``");

        value groupedFieldSet = collectFields(objectType, selectionSet, variableValues);

        variable Boolean hasFieldErrors = false;
        MutableMap<String, Result?> resultMap = HashMap<String, Result?>();

        for (responseKey->fields in groupedFieldSet) {
            String? fieldName = fields.first?.name;
            assert (exists fieldName);

            value field = objectType.fields[fieldName];
            if (is Null field) {
                // when can this happen?
                continue;
            }

            value pathToExecute = executedPath?.withTrailing(fieldName) else [fieldName];
            value responseValue = executeField(objectType, objectValue, fieldName, field.type, fields, variableValues, errors, pathToExecute, executor);
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

    Map<String, [Field+]> collectFields<Value>(GQLType<Value> objectType, [Selection+] selectionSet, Empty variableValues, MutableSet<Object>? visitedFragments=HashSet<Object>())
    {
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

    Result? |NullForError executeField<Value>(objectType, objectValue, fieldName, fieldType, fields, variableValues, errors, path, executor)
        given Value satisfies Result
    {
        GQLObjectType objectType;
        Anything objectValue;
        String fieldName;
        GQLType<Value> fieldType;
        [Field+] fields;
        Empty variableValues;

        MutableList<FieldError> errors;
        [String, <String|Integer>*] path;

        Executor executor;

        print("execute field ``path``");

        value argumentValues = coerceArgumentValues(objectType, objectValue, variableValues);
        value resolvedValue = resolveFieldValue(objectType, objectValue, fieldName, argumentValues, errors, path);
        return completeValues(fieldType, fields, resolvedValue, variableValues, errors, path, executor);
    }

    Empty coerceArgumentValues(objectType, objectValue, variableValues)
    {
        GQLObjectType objectType;
        Anything objectValue;
        Empty variableValues;
        return empty;
    }

    Anything resolveFieldValue(objectType, objectValue, fieldName, argumentValues, errors, path)
    {
        GQLObjectType objectType;
        Anything objectValue;
        String fieldName;
        Empty argumentValues;

        MutableList<FieldError> errors;
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

    Result? | NullForError innerCompleteValues(fieldType, fields, result, variableValues, inNonNull, errors, path, executor)
    {
        GQLType<Anything> fieldType;
        [Field+] fields;
        Anything result;
        Empty variableValues;

        Boolean inNonNull;

        MutableList<FieldError> errors;
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
            MutableList<Result?> elementResults = ArrayList<Result?>();
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
            return GQLListValue<Result>(elementResults.sequence());
        }
        case (is GQLScalarType<Result>) {
            if (is Integer result, result == 44) {errors.add(FieldError(path));}
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

    Result? |NullForError completeValues<Value>(GQLType<Value> fieldType, [Field+] fields, Anything result, Empty variableValues, errors, [String, <String|Integer>*] path, Executor executor)
        given Value satisfies Result
    {
        MutableList<FieldError> errors;

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
    shared formal List<FieldError>? errors;
}

shared interface Result
{
    // TODO what is a result
}
shared class GQLIntValue(shared Integer value_)
    satisfies Result
{

}

shared class GQLStringValue(shared String value_)
    satisfies Result
{

}
shared class GQLObjectValue(shared Map<String, Result?> value_)
    satisfies Result
{

}
shared class GQLListValue<out Value>(shared Value?[] elements)
    satisfies Result
    given Value satisfies Result
{

}
class ExtResultImplTODO(includedExecution, data, errors_)
    satisfies ExtResult
{
    shared actual Boolean includedExecution;
    shared actual GQLObjectValue? data;
    List<FieldError> errors_;
    shared actual List<FieldError>? errors = if (errors_.empty) then null else errors_;

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

shared class FieldError(path)
{
    shared String message => "not yet";
    shared Null locations = null;

    shared [String, <String|Integer>*] path;

    shared String stringPath => "``path.first````"".join(path.rest.map((el)=>if (is String el) then "/``el``" else "[``el.string``]"))``";
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
