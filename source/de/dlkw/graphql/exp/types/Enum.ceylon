shared class GQLEnumType(name_, values, description = null)
    extends GQLNullableType(TypeKind.enum, name_, description)
    satisfies ResultCoercing<String, Object> & InputCoercing<String, Object>
{
    String name_;
    String? description;
    {GQLEnumValue+} values;

    shared actual String name => name_;
    shared actual String | CoercionError doCoerceResult(Object value_)
    {
        print(value_);
        value r = values.find((el){print("scan ``el``, ``el.value_``");return el.value_ == value_;});
        if (exists r) {
            return r.name;
        }
        return CoercionError("``value_`` is not an allowed internal value for enum ``name``.");
    }

    // TODO support variable parsing as tokens instead of strings
    shared actual String doCoerceInput(Object input) => nothing;

    "Alias for [[values]] to provide the key/value pair in the GraphQL introspection type."
    shared {GQLEnumValue+} enumValues => values;
}

shared class GQLEnumValue(name, value__ =null, description=null, deprecated=false, deprecationReason=null)
{
    shared String name;
    assertGQLName(name);
    assert (name != "true" && name != "false" && name != "null");

    Anything value__;
    //value tmp = if (exists value__) then value__ else if (is Value name) then name else null;
    value tmp = if (exists value__) then value__ else name;
    shared Object value_ = tmp;

    shared String? description;
    shared Boolean deprecated;
    shared String? deprecationReason;
    if (!deprecated) {
        assert (is Null deprecationReason);
    }
}
