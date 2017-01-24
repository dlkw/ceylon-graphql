shared interface GQLWrapperType<out Inner, out InnerName>
    given Inner satisfies GQLType<InnerName>
    given InnerName of String | Null
{
    shared formal Inner inner;
}

shared class GQLNonNullType<out Inner, out InnerName>(inner)
    extends GQLType<Null>(TypeKind.nonNull, null)
    satisfies GQLWrapperType<Inner, InnerName>
    given Inner satisfies GQLNullableType<InnerName>
    given InnerName of String | Null
{
    shared actual Inner inner;
    shared Inner ofType => inner;

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

shared class GQLInputNonNullType<out Inner, out InnerName, out Coerced, in Input>(inner)
    extends GQLNonNullType<Inner, InnerName>(inner)
    satisfies GQLWrapperType<Inner, InnerName> & InputCoercing<InnerName, Coerced, Input>
    given Inner satisfies GQLNullableType<InnerName> & InputCoercing<InnerName, Coerced, Input>
    given InnerName of String | Null
    given Coerced satisfies Object
    given Input satisfies Object
{
    Inner inner;
    doCoerceInput = inner.doCoerceInput;

    shared actual Null name => null;
}

shared class GQLInputListType<out Inner, out InnerName, out Coerced, in Input>(inner)
    extends GQLListType<Inner, InnerName>(inner)
    satisfies GQLWrapperType<Inner, InnerName> & InputCoercing<InnerName, {Coerced*}, {Input*}>
    given Inner satisfies GQLType<InnerName> & InputCoercing<InnerName, Coerced, Input>
    given InnerName of String | Null
    given Coerced satisfies Object
    given Input satisfies Object
{
    Inner inner;
    shared actual [Coerced*]|CoercionError doCoerceInput({Input*} input)
    {
        class ElementCoercionException(shared CoercionError e) extends Exception(){}

        try {
            return input.map((el)
            {
                value elCoerced = inner.doCoerceInput(el);
                if (is CoercionError elCoerced) {
                    throw ElementCoercionException(elCoerced);
                }
                return elCoerced;
            }).sequence();
        }
        catch (ElementCoercionException e) {
            return CoercionError("element of list could not be coerced: ``e.e.message``");
        }
    }

    shared actual Null name => null;
}