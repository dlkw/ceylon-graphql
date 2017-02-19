shared abstract class GQLScalarType<out External, in ExternalInput, out Internal = External, in Input = Nothing>(String name, String? description = null)
    extends GQLNullableType<String>(TypeKind.scalar, name, description)
    satisfies ResultCoercing<String, External, ExternalInput> & InputCoercing<String, Internal, Input>
    given External satisfies Object
    given Internal satisfies Object
    given Input satisfies Object
    given ExternalInput satisfies Object
{
    shared actual Boolean isSameTypeAs(GQLType<Anything> other) => this === other;
    shared actual String wrappedName => name;
}

shared object gqlIntType
    extends GQLScalarType<Integer, Integer, Integer, Integer>("Int")
{
    shared actual Integer | CoercionError doCoerceResult(Integer result)
    {
        value coerced = doCoerceInput(result);
        return coerced;
    }

    shared actual Integer | CoercionError doCoerceInput(Integer input)
    {
        if (input >= 2 ^ 31) {
            return CoercionError("could not coerce positive Integer to 32 bit");
        }
        if (input < -(2 ^ 31)) {
            return CoercionError("could not coerce negative Integer to 32 bit");
        }
        return input;
    }
}

shared object gqlFloatType
    extends GQLScalarType<Float, Float | Integer, Float, Float | Integer>("Float")
{
    shared actual Float | CoercionError doCoerceResult(Float | Integer result)
    {
        value coerced = doCoerceInput(result);
        return coerced;
    }

    shared actual Float | CoercionError doCoerceInput(Float | Integer input)
    {
        switch (input)
        case (is Float) {
            // TODO need to check IEEE 754 bounds?
            return input;
        }
        case (is Integer) {
            return input.nearestFloat;
        }
    }
}

shared object gqlStringType
    extends GQLScalarType<String, String, String, String>("String")
{
    shared actual String | CoercionError doCoerceResult(String result)
    {
        value coerced = doCoerceInput(result);
        return coerced;
    }

    shared actual String doCoerceInput(String input) => input;
}

shared object gqlBooleanType
    extends GQLScalarType<Boolean, Boolean, Boolean, Boolean>("Boolean")
{
    shared actual Boolean | CoercionError doCoerceResult(Boolean result)
    {
        value coerced = doCoerceInput(result);
        return coerced;
    }

    shared actual Boolean doCoerceInput(Boolean input) => input;
}

shared class GQLIdType<Value>(doCoerceResult, doCoerceInput)
    extends GQLScalarType<Value, Object, Value, Object>("ID")
    given Value satisfies Object
{
    shared actual Value | CoercionError doCoerceResult(Object result);
    shared actual Value | CoercionError doCoerceInput(Object input);
}