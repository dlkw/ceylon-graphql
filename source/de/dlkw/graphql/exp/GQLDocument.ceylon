import de.dlkw.graphql.exp.types {
    undefined,
    Undefined,
    GQLType,
    assertGQLName,
    InputCoercing
}
shared class Document(definitions)
{
    <OperationDefinition | FragmentDefinition>[] definitions;
    value operationDefinitions = definitions.narrow<OperationDefinition>();

    variable value operationCount = 0;
    variable value firstOperationIsUnnamed = false;
    for (operationDefinition in operationDefinitions) {
        if (++operationCount == 1) {
            firstOperationIsUnnamed = operationDefinition.name is Null;
        }
        else {
            assert (operationDefinition.name exists && firstOperationIsUnnamed);
        }
    }

    shared OperationDefinition? operationDefinition(String? name)
    {
        if (exists name) {
            return operationDefinitions.filter((operationDefinition)=>operationDefinition.name?.equals(name) else false).first;
        }
        else if (operationDefinitions.shorterThan(2)) {
            return operationDefinitions.first;
        }
        else {
            throw AssertionError("Operation name must be specified if document contains more than one operation.");
        }
    }
}

shared class OperationDefinition(type, selectionSet, name = null, variableDefinitions_ = null)
{
    shared String? name;
    shared OperationType type;
    {<String->VariableDefinition<Object, String?>>*}? variableDefinitions_;
    shared Map<String, VariableDefinition<Object, String?>> variableDefinitions = if (exists variableDefinitions_) then map(variableDefinitions_) else map([]);
    shared [Selection+] selectionSet;
}


shared class VariableDefinition<Value, out TypeName>(type, defaultValue = undefined)
    given Value satisfies Object
    given TypeName of String | Null
{
    shared GQLType<TypeName> & InputCoercing<Object, Nothing> type;
    shared Value?|Undefined defaultValue;
}

shared class OperationType of query | mutation
{
    shared new query{}
    shared new mutation{}
}

shared alias Selection => Field | FragmentSpread | InlineFragment;
shared alias DocumentScalarValue => Integer|Float|String|Boolean|Null;

shared class Field(name, alias_=null, arguments_=null, directives=null, selectionSet=null)
{
    shared String name;
    assertGQLName(name);

    shared String? alias_;
    if (exists alias_) {
        assertGQLName(alias_);
    }

    shared String responseKey => if (exists alias_) then alias_ else name;

    [Argument+]? arguments_;
    shared Map<String, Anything> arguments = if (exists arguments_) then map(arguments_.map((arg)=>arg.name->arg.value_)) else emptyMap;
    shared [Directive+]? directives;

    shared [Selection+]? selectionSet;
}

shared class Argument(name, value_)
{
    shared String name;
    assertGQLName(name);

    shared DocumentScalarValue value_;
}

shared class Directive()
{

}

shared class FragmentSpread()
{
}

shared class InlineFragment()
{
}

shared class FragmentDefinition()
{
}

Document doci()
{
    value doc =Document([OperationDefinition(OperationType.query, [Field{
                name="fA";
                selectionSet = [Field("f2")];
    }])]);
    return doc;
}
