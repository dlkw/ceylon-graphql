import ceylon.logging {
    addLogWriter,
    writeSimpleLog
}
import ceylon.test {
    test,
    fail
}

import de.dlkw.graphql.exp {
    Schema,
    Document,
    OperationDefinition,
    OperationType,
    Field,
    FragmentDefinition,
    FragmentSpread
}
import de.dlkw.graphql.exp.types {
    GQLField,
    gqlStringType,
    GQLObjectType
}

test
shared void introspection1() {
    addLogWriter(writeSimpleLog);

    Schema schema = Schema {
        queryRoot = GQLObjectType("q", {GQLField("f", gqlStringType)}, {}, "description of type q");
        mutationRoot = null;
    };

    Document document = Document(
        [
            FragmentDefinition{
                name="typeFragment";
                typeCondition=null;
                selectionSet=[
                    Field("kind"),
                    Field("name"),
                    Field("description"),
                    Field{
                        name="ofType";
                        selectionSet=[
                            Field("kind"),
                            Field("name"),
                            Field("description"),
                            Field{
                                name="ofType";
                                selectionSet=[
                                    Field("kind"),
                                    Field("name"),
                                    Field("description"),
                                    Field{
                                        name="ofType";
                                        selectionSet=[
                                            Field("kind"),
                                            Field("name"),
                                            Field("description")
                                        ];
                                    }
                                ];
                            }
                        ];
                    }
                ];
            },
            FragmentDefinition{
                name="directiveFragment";
                typeCondition=null;
                selectionSet=[
                    Field("name"),
                    Field("description"),
                    Field{
                        name="locations";
//                        selectionSet=[FragmentSpread("directiveLocationFragment")];
                    },
                    Field{
                        name="args";
                        selectionSet=[FragmentSpread("inputValueFragment")];
                    }
                ];
            },
            FragmentDefinition{
                name="inputValueFragment";
                typeCondition=null;
                selectionSet=[
                    Field("name"),
                    Field("description"),
                    Field{
                        name="type";
                        selectionSet=[FragmentSpread("typeFragment")];
                    },
                    Field("defaultValue")
                ];
            },
            OperationDefinition{
                type=OperationType.query;
                selectionSet=[
                    Field{
                        name="__schema";
                        selectionSet=[
                            Field{
                                name="types";
                                selectionSet=[FragmentSpread("typeFragment")];
                            },
                            Field{
                                name="queryType";
                                selectionSet=[FragmentSpread("typeFragment")];
                            },
                            Field{
                                name="mutationType";
                                selectionSet=[FragmentSpread("typeFragment")];
                            },
                            Field {
                                name="directives";
                                selectionSet=[FragmentSpread("directiveFragment")];
                            }
                        ];
                    }
                ];
            }
        ]
    );

    value result = schema.executeRequest(document);
    value errors = result.errors;
    if (exists errors) {
        print(errors);
        fail();
    }
    assert (exists data = result.data);

    print(data);
}