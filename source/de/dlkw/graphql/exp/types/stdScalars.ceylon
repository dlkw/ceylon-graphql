shared abstract class GQLScalarType<out External, out Internal = External, in Input = Nothing>(String name, String? description = null)
    extends GQLNullableType<String>(TypeKind.scalar, name, description)
    satisfies ResultCoercing<External> & InputCoercing<Internal, Input>
    given External satisfies Object
    given Internal satisfies Object
    given Input satisfies Object
{
}

shared object gqlIntType
    extends GQLScalarType<Integer, Integer, Integer>("Int")
{
    shared actual Integer | CoercionError coerceResult(Object result)
    {
        if (is Integer result) {
            return coerceInput(result);
        }
        throw;//FIXME
    }

    shared actual Integer | CoercionError coerceInput(Integer input)
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
    extends GQLScalarType<Float, Float, Float | Integer>("Float")
{
    shared actual Float | CoercionError coerceResult(Object result)
    {
        if (is Float | Integer result) {
            return coerceInput(result);
        }
        throw;//FIXME
    }

    shared actual Float | CoercionError coerceInput(Float | Integer input)
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
    extends GQLScalarType<String, String, String>("String")
{
    shared actual String | CoercionError coerceResult(Object result)
    {
        if (is String result) {
            return coerceInput(result);
        }
    throw;//FIXME
}

    shared actual String | CoercionError coerceInput(String input) => input;
}

shared object gqlBooleanType
    extends GQLScalarType<Boolean, Boolean, Boolean>("Boolean")
{
    shared actual Boolean | CoercionError coerceResult(Object result)
    {
        if (is Boolean result) {
            return coerceInput(result);
        }
        throw;//FIXME
    }

    shared actual Boolean | CoercionError coerceInput(Boolean input) => input;
}

shared class GQLIdType<Value>(coerceResult, coerceInput)
    extends GQLScalarType<Value, Value, Object>("ID")
    given Value satisfies Object
{
    shared actual Value | CoercionError coerceResult(Object result);
    shared actual Value | CoercionError coerceInput(Object input);
}