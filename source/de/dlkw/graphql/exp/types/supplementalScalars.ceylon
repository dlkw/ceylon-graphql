import ceylon.language.meta {
    type
}
import ceylon.time {
    Instant
}
import ceylon.time.iso8601 {
    parseZoneDateTime
}
shared object gqlInstantType
    extends GQLScalarType<String, Instant, Object>("Instant",
        "An instant in time, or timestamp, in
         ISO 8601 format (extended format) with
         a time zone designator Z (UTC time zone)")
{
    shared actual String | CoercionError coerceResult(Object result)
    {
        if (is Instant result) {
            return result.string;
        }
        return CoercionError("not an Instant: ``result`` (of type ``type(result)``)");
    }

    shared actual Instant | CoercionError coerceInput(Object input)
    {
        if (is String input) {
            if (exists instant = parseZoneDateTime(input) ?. instant) {
                return instant;
            }
            return CoercionError("not a valid Instant string value: ``input``");
        }
        return CoercionError("not an Integer: ``input`` (of type ``type(input)``)");
    }
}
