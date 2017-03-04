import de.dlkw.graphql.exp.types {
    assertGQLName,
    ArgumentDefinition
}

shared class DirectiveDefinition(name, description, locations, args)
{
    shared String name;
    assertGQLName(name);

    shared String? description;

    shared <String->ArgumentDefinition<Anything>>[] args;

    shared [DirectiveLocation+] locations;
}

shared class DirectiveLocation
{
    shared new query{}
    shared new mutation{}
    shared new field{}
    shared new fragmentDefinition{}
    shared new fragmentSpread{}
    shared new inlineFragment{}
}