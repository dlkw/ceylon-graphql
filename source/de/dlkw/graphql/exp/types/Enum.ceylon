shared class GQLEnumType<Value=String>(name_, values, description = null)
    extends GQLNullableType<String>(TypeKind.enum, name_, description)
    satisfies ResultCoercing<String, String, Value> & InputCoercing<String, Value, String>
    given Value satisfies Object
{
    String name_;
    String? description;
    [GQLEnumValue<Value>+] values;

    shared actual String | CoercionError doCoerceResult(Value value_)
    {
        print(value_);
        value r = values.find((el){print("scan ``el``, ``el.value_ else "<null>"``");return el.value_ == value_;});
        if (exists r) {
            return r.name;
        }
        return CoercionError("``value_`` is not an allowed internal value for enum ``name``.");
    }

    // TODO support variable parsing as tokens instead of strings
    shared actual Value | CoercionError doCoerceInput(String input) => values.find((v) => v.name == input)?.value_ else CoercionError("no value ``input``");

    "Alias for [[values]] to provide the key/value pair in the GraphQL introspection type."
    shared {GQLEnumValue<Value>+} enumValues => values;
    shared actual Boolean isSameTypeAs(GQLType<Anything> other) => this === other;

    shared actual String wrappedName => name_;

}

shared class GQLEnumValue<Value=String>(name, value__=null, description=null, deprecated=false, deprecationReason=null)
    given Value satisfies Object
{
    shared String name;
    assertGQLName(name);
    assert (name != "true" && name != "false" && name != "null");

    Value? value__;
    Value tmp;
    if (exists value__) {
        tmp = value__;
    }
    else if (is Value name) {
        tmp = name;
    }
    else {
        throw AssertionError("need to specify a value for non-string enums");
    }

    shared Value value_ = tmp;

    shared String? description;
    shared Boolean deprecated;
    shared String? deprecationReason;
    if (!deprecated) {
        assert (is Null deprecationReason);
    }
}
