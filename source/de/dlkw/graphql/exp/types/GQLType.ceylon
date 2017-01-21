import ceylon.language.meta {
    type
}

shared abstract class GQLType(kind, name_, description = null)
    satisfies Named
{
    shared TypeKind kind;

    String? name_;
    if (exists name_) {
        assertGQLName(name_);
    }
    shared default actual String? name => name_;

    shared default String? description;
    shared formal String wrappedName;
    shared formal Boolean isSameTypeAs(GQLType other);
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
shared interface Named
{
    shared formal String? name;
}

shared interface ResultCoercing<out Coerced, in Input>
    satisfies Named
    given Coerced satisfies Object
    given Input satisfies Object
{
    "Coerces a result value obtained from field resolution to the corresponding GQLValue value
     according to the GraphQL result coercion rules."
    shared formal Coerced | CoercionError doCoerceResult(Input result);

    shared Coerced? | CoercionError coerceResult(Anything input)
    {
        if (is Null input) {
            return null;
        }

        if (is Input input) {
            return doCoerceResult(input);
        }

        String effName = name else type(this).string;
        return CoercionError("Cannot result-coerce input value ``input`` of type ``type(input)`` to `` `Coerced` `` as ``effName``: only possible for input type `` `Input` ``.");
    }
}

shared interface InputCoercing<out Coerced, in Input = Coerced>
    satisfies Named
    given Coerced satisfies Object
    given Input satisfies Object
{
    "Coerces an input value (variable or argument value) to the corresponding GQLValue value
     according to the GraphQL input coercion rules."
    shared formal Coerced | CoercionError doCoerceInput(Input input);

    shared Coerced? | CoercionError ddCI(Anything input)
    {
        if (is Null input) {
            return null;
        }

        if (is Input input) {
            return doCoerceInput(input);
        }

        String effName = name else type(this).string;
        return CoercionError("Cannot input-coerce input value ``input`` of type ``type(input)`` to `` `Coerced` `` as ``effName``: only possible for input type `` `Input` ``.");
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

shared abstract class GQLNullableType(kind, name, description = null)
    extends GQLType(kind, name, description)
{
    TypeKind kind;
    String? name;
    String? description;
}
