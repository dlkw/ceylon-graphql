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

shared class OperationDefinition(type, selectionSet, name = null)
{
    shared String? name;
    shared OperationType type;
    shared [Selection+] selectionSet;
}

shared class OperationType of query | mutation
{
    shared new query{}
    shared new mutation{}
}

shared alias Selection => Field | FragmentSpread | InlineFragment;

shared class Field(name, alias_=null, arguments=null, directives=null, selectionSet=null)
{
    shared String name;
    assertGQLName(name);

    shared String? alias_;
    if (exists alias_) {
        assertGQLName(alias_);
    }

    shared String responseKey => if (exists alias_) then alias_ else name;

    shared [Argument+]? arguments;
    shared [Directive+]? directives;

    shared [Selection+]? selectionSet;
}

shared class Argument(name, value_)
{
    shared String name;
    assertGQLName(name);

    shared String | Null value_;
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
