import de.dlkw.graphql.exp.types {
    undefined,
    Undefined,
    GQLType,
    assertGQLName,
    InputCoercing,
    Named
}

shared interface IFragmentTypeConditioned
{
    shared formal String? typeCondition;
}

shared class Document(definitions)
{
    <OperationDefinition | FragmentDefinition>[] definitions;
    value operationDefinitions = definitions.narrow<OperationDefinition>();
    value fragmentDefinitions = definitions.narrow<FragmentDefinition>();

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

    shared FragmentDefinition? fragmentDefinition(String name) =>
        fragmentDefinitions.filter((fDef)=>fDef.name.equals(name)).first;

    shared OperationDefinition? operationDefinition(String? name)
    {
        if (exists name) {
            return operationDefinitions.filter((oDef)=>oDef.name?.equals(name) else false).first;
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
    shared GQLType<TypeName> & InputCoercing<TypeName, Object, Nothing> type;
    shared Value?|Undefined defaultValue;
}

shared class OperationType of query | mutation
{
    shared new query{}
    shared new mutation{}
}

shared alias Selection => AField | FragmentSpread | InlineFragment;
shared alias DocumentScalarValue => Integer|Float|String|Boolean|Null;

shared abstract class AField(name, alias_)
{
    shared String name;
    assertGQLName(name);

    shared String? alias_;
    if (exists alias_) {
        assertGQLName(alias_);
    }

    shared String responseKey => if (exists a = alias_) then a else name;

    shared formal Map<String, Anything> arguments;

    shared formal [Selection+]? selectionSet;
}
shared class Field(name, alias_=null, arguments_=null, directives=null, selectionSet=null)
    extends AField(name, alias_)
{
    String name;
    String? alias_;

    [Argument+]? arguments_;
    shared actual Map<String, Anything> arguments = if (exists arguments_) then map(arguments_.map((arg)=>arg.name->arg.value_)) else emptyMap;
    shared [Directive+]? directives;

    shared actual [Selection+]? selectionSet;
}

shared class Argument(name, value_)
{
    shared String name;
    assertGQLName(name);

    shared Anything value_;
}

shared class Directive()
{

}

shared abstract class Fragment(selectionSet, typeCondition, directives)
{
    shared [Selection+] selectionSet;
    shared String? typeCondition;
    shared [Directive+]? directives;
}

shared class FragmentSpread(name, directives=null)
{
    shared String name;
    assertGQLName(name);
    assert (name != "on");//FIXME

    shared [Directive*]? directives;
}

shared class InlineFragment(selectionSet, typeCondition = null, directives = null)
    extends Fragment(selectionSet, typeCondition, directives)
{
    [Selection+] selectionSet;
    String? typeCondition;
    [Directive+]? directives;
}

shared class FragmentDefinition(name, selectionSet, typeCondition, directives = null)
    extends Fragment(selectionSet, typeCondition, directives)
{
    shared String name;
    [Selection+] selectionSet;
    String? typeCondition;
    [Directive+]? directives;
}

Document doci()
{
    value doc = Document([OperationDefinition(OperationType.query, [Field{
                name="fA";
                selectionSet = [Field("f2")];
    }])]);
    return doc;
}
