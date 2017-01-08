shared interface GQLWrapperType<out Inner, out InnerName>
    given Inner satisfies GQLType<InnerName>
    given InnerName of String | Null
{
    shared formal Inner inner;
}

shared class GQLNonNullType<out Inner, out InnerName = String?>(inner)
    extends GQLType<Null>(TypeKind.nonNull, null)
    satisfies GQLWrapperType<Inner, InnerName>
    given Inner satisfies GQLNullableType<InnerName>
    given InnerName of String | Null
{
    shared actual Inner inner;

    shared Inner ofType => inner;
}

shared class GQLListType<out Inner, out InnerName = String?>(inner)
    extends GQLNullableType<Null>(TypeKind.list, null)
    satisfies GQLWrapperType<Inner, InnerName>
    given Inner satisfies GQLType<InnerName>
    given InnerName of String | Null
{
    shared actual Inner inner;
}
