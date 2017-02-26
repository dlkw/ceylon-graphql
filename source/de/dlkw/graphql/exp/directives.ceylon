import de.dlkw.graphql.exp.types {
    assertGQLName,
    ArgumentDefinition
}

shared class DirectiveDefinition(name, description, arguments)
{
    shared String name;
    assertGQLName(name);

    shared String? description;

    shared <String->ArgumentDefinition<Anything>>[] arguments;

    // FIXME locations
}
