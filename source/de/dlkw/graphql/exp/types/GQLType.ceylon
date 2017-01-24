import ceylon.language.meta {
    type
}

shared abstract class GQLType<out Name>(kind, name_, description = null)
    satisfies Named<Name>
    given Name of String | Null
{
    shared TypeKind kind;

    shared Name name_;
    if (is String name_) {
        assertGQLName(name_);
    }
    shared default actual Name name => name_;

    shared default String? description;
    shared formal String wrappedName;

    "Determines if this type is the same as another type. This method is needed because
     types with a name can be compared by identity,
     but wrapper types can have different instances which only need to be of the same type and
     must wrap the same type."
    shared formal Boolean isSameTypeAs(GQLType<Anything> other);
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

shared interface ResultCoercing<out Name, out Coerced, in Input>
    satisfies Named<Name>
    given Coerced satisfies Object
    given Input satisfies Object
    given Name of String | Null
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

        String effName = (name else type(this).string) of String;
        return CoercionError("Cannot result-coerce input value ``input`` of type ``type(input)`` to `` `Coerced` `` as ``effName``: only possible for input type `` `Input` ``.");
    }
}

shared interface InputCoercing<out Name, out Coerced, in Input = Coerced>
    satisfies Named<Name>
    given Coerced satisfies Object
    given Input satisfies Object
    given Name of String | Null
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

        String effName = (name else type(this).string) of String;
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

shared abstract class GQLNullableType<Name>(kind, name, description = null)
    extends GQLType<Name>(kind, name, description)
    given Name of String | Null
{
    TypeKind kind;
    Name name;
    String? description;
}
