import de.dlkw.graphql.exp.types {
    undefined,
    Undefined,
    GQLType,
    assertGQLName,
    InputCoercingBase
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

    variable value unnamedOperationFound = false;
    for (operationDefinition in operationDefinitions) {
        if (operationDefinition.name is Null) {
            if (unnamedOperationFound) {
                throw AssertionError("more than one unnamed operation in document");
            }
            unnamedOperationFound = true;
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


shared class VariableDefinition<out Value, out TypeName>(type, defaultValue = undefined)
    given Value satisfies Object
    given TypeName of String | Null
{
    shared GQLType<TypeName> & InputCoercingBase<TypeName, Value> type;
    shared Value?|Undefined defaultValue;
}

shared class OperationType of query | mutation
{
    shared new query{}
    shared new mutation{}
}

shared alias Selection => Field | FragmentSpread | InlineFragment;
shared alias DocumentScalarValue => Integer|Float|String|Boolean|Null;

shared interface DirectivesPossible
{
    shared formal [Directive+]? directives;
}

shared class Field(name, alias_=null, arguments_=null, directives=null, selectionSet=null)
    satisfies DirectivesPossible
{
    shared String name;
    assertGQLName(name);

    shared String? alias_;
    if (exists alias_) {
        assertGQLName(alias_);
    }

    shared String responseKey => if (exists a = alias_) then a else name;

    {Argument+}? arguments_;
    shared Map<String, Anything> arguments = if (exists arguments_) then map(arguments_.map((arg)=>arg.name->arg.value_)) else emptyMap;

    shared actual [Directive+]? directives;

    shared [Selection+]? selectionSet;
}

shared class Argument(name, value_)
{
    shared String name;
    assertGQLName(name);

    shared Anything value_;
}

shared class Directive(name, arguments)
{
    shared String name;
    assertGQLName(name);

    shared [Argument+]? arguments;
}

shared abstract class Fragment(selectionSet, typeCondition, directives)
    satisfies DirectivesPossible
{
    shared [Selection+] selectionSet;
    shared String? typeCondition;
    shared actual [Directive+]? directives;
}

shared class FragmentSpread(name, directives=null)
    satisfies DirectivesPossible
{
    shared String name;
    assertGQLName(name);
    assert (name != "on");//FIXME

    shared actual [Directive+]? directives;
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

/*
shared alias InputValue => SVal | IVal | FVal | NVal | BVal | EVal | LVal | OVal;
shared abstract class Vall<V, T>(shared T v) of V
given V of SVal | IVal | FVal | NVal | BVal | EVal | LVal | OVal
{}

shared class SVal(String val) extends Vall<SVal, String>(val){}
shared class IVal(Integer val) extends Vall<IVal, Integer>(val){}
shared class FVal(Float val) extends Vall<FVal, Float>(val){}
shared class NVal() extends Vall<NVal, Null>(null){}
shared class BVal(Boolean val) extends Vall<BVal, Boolean>(val){}
shared class EVal(String val) extends Vall<EVal, String>(val){}
shared class LVal({InputValue*} val) extends Vall<LVal, {InputValue*}>(val){}
shared class OVal(Map<String, InputValue> val) extends Vall<OVal, Map<String, InputValue>>(val){}
*/

shared alias DocumentValue<out V> => String | Integer | Float | Boolean | EnumLiteral | IObject<V> | Null | IList<V> | V;
shared class EnumLiteral(value_)
{
    shared String value_;
    assert (!value_ in {"null, true. false"});

    string => "enum literal \"``value_``\"";
}

shared class IObject<out  V>({<String->DocumentValue<V>>*} fields)
    satisfies Map<String, DocumentValue<V>>
    given V satisfies Var
{
    import ceylon.language { outerMap = map }
    value store = outerMap(fields);
    shared actual Boolean defines(Object key) => store.defines(key);

    shared actual DocumentValue<V>? get(Object key) => store.get(key);

    shared actual Iterator<String->DocumentValue<V>> iterator() => store.iterator();

    shared actual Integer hash => store.hash;

    shared actual Boolean equals(Object that) => store.equals(that);
}

shared class IList<out V>(Sequential<DocumentValue<V>> items)
    satisfies List<DocumentValue<V>>
    given V satisfies Var
{
    // TODO is this enough to override performance-wise?
    getFromFirst = items.getFromFirst;
    lastIndex => items.lastIndex;

    hash => items.hash;
    equals = items.equals;
}

shared class Var(name)
{
    shared String name;
}
