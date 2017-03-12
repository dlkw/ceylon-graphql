shared class GQLError(message, locations)
{
    shared String message;
    shared [Location+]? locations;
}
shared class QueryError(String message, [Location+]? locations)
    extends GQLError(message, locations)
{}

shared class Location(shared Integer line, shared Integer column)
{
    assert (line >= 0);
    assert (column >= 0);
}
