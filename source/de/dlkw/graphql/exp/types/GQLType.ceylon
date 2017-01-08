import ceylon.language.meta {
    type
}

shared abstract class GQLType<out Name = String?>(kind, name, description = null)
    satisfies Named<Name>
    given Name of String | Null
{
    shared TypeKind kind;

    shared actual Name name;
    if (exists name) {
        assertGQLName(name of String);
    }

    shared default String? description;
}

shared void assertGQLName(String name)
{
    assert (exists first = name.first);
    assert (first in 'a'..'z' || first in 'A' ..'Z' || first == '_');
    for (c in name[1...]) {
        assert (c in 'a'..'z' || c in 'A' ..'Z' || c in '0'.. '9'|| c == '_');
    }
}

"Used to provide a type name on coercion errors."
shared interface Named<out Name>
    given Name of String | Null
{
    shared formal Name name;
}

shared interface ResultCoercing<out Value>
    given Value satisfies Anything
{
    "Coerces a result value obtained from field resolution to the corresponding GQLValue value
     according to the GraphQL result coercion rules."
    shared formal Value | CoercionError coerceResult(Object result);
}

shared interface InputCoercing<out Coerced, in Input>
    satisfies Named<String>
    given Coerced satisfies Object
    given Input satisfies Object
{
    "Coerces an input value (variable or argument value) to the corresponding GQLValue value
     according to the GraphQL input coercion rules."
    shared formal Coerced | CoercionError coerceInput(Input input);

    shared Coerced? | CoercionError dCI(Anything input)
    {
        if (is Null input) {
            return null;
        }

        if (is Input input) {
            return coerceInput(input);
        }

        String effName = name else type(this).string;
        return CoercionError("Cannot coerce input value ``input`` of type ``type(input)`` to `` `Coerced` `` as ``effName``: only possible for input type `` `Input` ``.");
    }
}

shared class CoercionError(message)
{
    shared String message;
}

shared class TypeKind of scalar|\iobject|\iinterface|union|enum|inputObject|list|nonNull
{
    shared new scalar{}
    shared new \iobject{}
    shared new \iinterface{}
    shared new union{}
    shared new enum{}
    shared new inputObject{}
    shared new list{}
    shared new nonNull{}
}

shared abstract class GQLNullableType<Name>(kind, name, description = null)
    extends GQLType<Name>(kind, name, description)
    given Name of String | Null
{
    TypeKind kind;
    Name name;
    String? description;
}
