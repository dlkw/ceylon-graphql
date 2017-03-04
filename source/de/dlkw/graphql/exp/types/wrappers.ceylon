import ceylon.language.meta {
    type
}

import de.dlkw.graphql.exp {
    Var
}
shared interface GQLWrapperType<out Inner, out InnerName>
    satisfies Named<Null>
    given Inner satisfies GQLType<InnerName>
    given InnerName of String | Null
{
    shared formal Inner inner;
    shared Inner ofType => inner;
}

shared class GQLNonNullType<out Inner, out InnerName>(inner)
    extends GQLType<Null>(TypeKind.nonNull, null)
    satisfies GQLWrapperType<Inner, InnerName>
    given Inner satisfies GQLNullableType<InnerName>
    given InnerName of String | Null
{
    shared actual Inner inner;

    shared actual String wrappedName => "``inner.wrappedName``!";

    shared actual Boolean isSameTypeAs(GQLType<Anything> other) {
        if (is GQLNonNullType<GQLType<Anything>, InnerName> other) {
            return inner.isSameTypeAs(other.inner);
        }
        return false;
    }
}

shared class GQLListType<out Inner, out InnerName>(inner)
    extends GQLNullableType<Null>(TypeKind.list, null)
    satisfies GQLWrapperType<Inner, InnerName>
    given Inner satisfies GQLType<InnerName>
    given InnerName of String | Null
{
    shared actual Inner inner;
    shared actual String wrappedName => "[``inner.wrappedName``]";

    shared actual Boolean isSameTypeAs(GQLType<Anything> other) {
        if (is GQLListType<GQLType<Anything>, InnerName> other) {
            return inner.isSameTypeAs(other.inner);
        }
        return false;
    }
}

shared class GQLInputNonNullType<out Inner, out InnerName, out Coerced>(inner)
    extends GQLNonNullType<Inner, InnerName>(inner)
    satisfies GQLWrapperType<Inner, InnerName> & InputCoercingBase<Null, Coerced>
    given Inner satisfies GQLNullableType<InnerName> & InputCoercingBase<InnerName, Coerced>
    given InnerName of String | Null
    given Coerced satisfies Object
{
    Inner inner;
    coerceInput = inner.coerceInput;

    shared actual Null name => null;
}

shared class GQLInputListType<out Inner, out InnerName, out Coerced>(inner)
    extends GQLListType<Inner, InnerName>(inner)
    satisfies GQLWrapperType<Inner, InnerName> & InputCoercingBase<Null, {Coerced?|Var*}>
    given Inner satisfies GQLType<InnerName> & InputCoercingBase<InnerName, Coerced>
    given InnerName of String | Null
    given Coerced satisfies Object
{
    Inner inner;
    shared actual {Coerced?|Var*}? | Var | CoercionError coerceInput(Anything input)
    {
        if (is Null | Var input) {
            return input;
        }

        if (is {Anything*} input) {
            class ElementCoercionException(shared CoercionError e) extends Exception(){}
            try {
                return input.map((el)
                {
                    if (is Null | Var el) {
                        return el;
                    }
                    value elCoerced = inner.coerceInput(el);
                    if (is CoercionError elCoerced) {
                        throw ElementCoercionException(elCoerced);
                    }
                        return elCoerced;
/*                    }
                    else {
                        String effName = (name else type(inner).string) of String;
                        throw ElementCoercionException(CoercionError("cannot input-coerce list item value ``el`` of type ``type(el)`` to `` `Coerced` `` as ``effName``: only possible for input type `` `Input` ``."));
                    }
*/                }).sequence();
            }
            catch (ElementCoercionException e) {
                return CoercionError("list item could not be coerced: ``e.e.message``");
            }
        }

        return CoercionError("Cannot input-coerce input value ``input`` of type ``type(input)`` to `` `{Coerced*}` `` as ``type(this)``: only possible for input type FIXME."); // FIXME
    }

    shared actual Null name => null;
}

shared void test()
{
    <String|Integer|Null|Var>[] l = nothing;
    <String|Var>[] k = nothing;
    <String|Integer|Null|Var>[] m = k;
}