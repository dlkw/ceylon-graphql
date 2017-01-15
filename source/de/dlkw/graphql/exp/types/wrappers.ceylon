shared interface GQLWrapperType<out Inner>
    //given Inner satisfies GQLType
{
    shared formal Inner inner;
}

shared class GQLNonNullType<out Inner>(inner)
    extends GQLType(TypeKind.nonNull, null)
    satisfies GQLWrapperType<Inner>
    //given Inner satisfies GQLNullableType
{
    shared actual Inner inner;

    shared Inner ofType => inner;

    shared actual Null name => null;
}

shared class GQLListType<out Inner>(inner)
    extends GQLNullableType(TypeKind.list, null)
    satisfies GQLWrapperType<Inner>
    given Inner satisfies GQLType
{
    shared actual Inner inner;

    //shared actual Null name => null;
}


shared interface GQLInpWrapperType<out Inner, out Coerced, in Input>
satisfies GQLWrapperType<Inner> & InputCoercing<Coerced, Input>
    given Inner satisfies InputCoercing<Coerced, Input>
    given Coerced satisfies Object
    given Input satisfies Object
{}

shared class GQLInpNonNullType<out Inner, out Coerced, in Input>(inner)
    extends GQLNonNullType<Inner>(inner)
    satisfies GQLInpWrapperType<Inner, Coerced, Input>
    given Inner satisfies InputCoercing<Coerced, Input>
    given Coerced satisfies Object
    given Input satisfies Object
{
    Inner inner;
    doCoerceInput = inner.doCoerceInput;
}
