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
    extends GQLScalarType<String, Instant, Instant, String|Instant>("Instant",
        "An instant in time, or timestamp, in
         ISO 8601 format (extended format) with
         a time zone designator Z (UTC time zone)")
{
    shared actual String | CoercionError doCoerceResult(Instant result)
    {
        return result.string;
    }

    shared actual Instant | CoercionError doCoerceInput(String|Instant input)
    {
        if (is Instant input) {
            return input;
        }

        if (exists instant = parseZoneDateTime(input) ?. instant) {
            return instant;
        }
        return CoercionError("not a valid Instant string value: ``input``");
    }
}
