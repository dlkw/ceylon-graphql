import ceylon.json {
    JsonObject,
    Value,
    JsonArray
}
import ceylon.language.meta {
    type
}
import ceylon.logging {
    addLogWriter,
    writeSimpleLog,
    defaultPriority,
    debug
}

import de.dlkw.graphql.exp {
    Document,
    Schema,
    OperationDefinition,
    Field,
    OperationType,
    FieldError,
    GQLError,
    QueryError,
    Argument,
    VariableDefinition,
    Var
}
import de.dlkw.graphql.exp.types {
    GQLNonNullType,
    gqlIntType,
    GQLListType,
    GQLEnumType,
    GQLEnumValue,
    GQLField,
    GQLObjectType,
    ArgumentDefinition,
    GQLInputObjectType,
    GQLInputField,
    GQLInputNonNullType
}

shared JsonObject executeRequest(Document doc, String? operationName, JsonObject? variableValues, Schema schema, Anything rootValue)
{
    value res = schema.executeRequest(doc, variableValues, operationName, rootValue);
    print(res.data);
    if (res.includedExecution) {
        if (exists errors = res.errors) {
            return JsonObject({"data" -> mkJsonObject(res.data), "errors"->mkJsonErrors(errors)});
        }
        return JsonObject({"data" -> mkJsonObject(res.data)});
    }
    assert (exists errors = res.errors);
    return JsonObject({"errors" -> mkJsonErrors(errors)});
}

JsonObject? mkJsonObject(Map<String, Anything>? gqlValue)
    => if (exists gqlValue) then JsonObject(gqlValue.map((key->item) => key->mkJsonValue(item))) else null;

Value mkJsonValue(Anything gqlValue)
{
    switch (gqlValue)
    case (is Null) {
        return null;
    }
    case (is Integer | Boolean | String) {
        return gqlValue;
    }
    case (is Map<String, Anything>) {
        return mkJsonObject(gqlValue);
    }
    case (is Anything[]) {
        return JsonArray(gqlValue.map((element) => mkJsonValue(element)));
    }
    else {
        throw AssertionError("found ``type(gqlValue)``");
    }
}

JsonArray mkJsonErrors({GQLError*} errors)
    => JsonArray(errors.map((error)
        {
            if (is FieldError error) {
                return JsonObject({
                    "message"->error.message,
                    if (exists locations = error.locations) then "locations"->locations else null,
                    "path"->error.stringPath
                }.coalesced);
            }
            else if (is QueryError error) {
                return JsonObject({"message"->"query error"});
            }
            else {
                throw;
            }
        }
    ));

shared void run()
{
    addLogWriter(writeSimpleLog);
    defaultPriority = debug;

    variable Integer aa = 0;
    value queryRoot = GQLObjectType("n", {
        GQLField{
            "obj";
            GQLObjectType("A", {
                GQLField("of1s1", gqlIntType)
            });
            arguments = map({
                "inpObj" -> ArgumentDefinition(GQLInputNonNullType<GQLInputObjectType, String, Map<String, Anything>, Map<String, Anything>>(GQLInputObjectType(
                    "of1",
                    null,
                    {
                        GQLInputField("of1s1", gqlIntType, null)
                    }
                )))
            });
            resolver = (Anything x, Map<String, Object?> y)
            {
                return y["inpObj"];
            };
        },
        GQLField{
            "fA";
            gqlIntType;
            "descA";
            deprecated=true;
            deprecationReason="mmmmmmmm";
        },
        GQLField{
            name="fB";
            type=GQLNonNullType(gqlIntType);
            description="descB";
        },
        GQLField{
            name="fC";
            type=GQLNonNullType(
//            type=
                GQLObjectType("x", {
                GQLField{
                        name="sub1";
//                        type=GQLNonNullType(GQLIntType());
                    type=gqlIntType;
//                    resolver=(a, b){return 5/0;};
                },
                GQLField{
                    name="sub2";
//                    type=GQLNonNullType(
                    type=
                        GQLObjectType("xx", {
                            GQLField{
                                name="subsub21";
//                                type=GQLNonNullType(GQLIntType());
                                type=gqlIntType;
                                resolver=(a, b){return 5/0;};
                            },
                            GQLField{
                                name="subsub22";
//                                type=GQLNonNullType(GQLIntType());
                                type=gqlIntType;
                                resolver=(a, b){return 5/0;};
                            }
                        })
                    ;
                }
            })
            );
            description="descB";
        },
        GQLField("nicks", GQLNonNullType<GQLListType<GQLNonNullType<GQLObjectType, String>, Null>, Null>(GQLListType(GQLNonNullType(GQLObjectType{
            name="kk";
            fields_={GQLField{
                name="n1";
                type=GQLNonNullType(gqlIntType);
//                type=GQLIntType();
                resolver=(a, b){return if (++aa%2==0) then 5/0 else aa;};
            }};
        }))), "descNicks"),
        GQLField{
                name="enum";
                type=GQLEnumType{"Enum1";
                        [GQLEnumValue<>{"V1";"5";"descr";true;"Deprecation Reason";},
                        GQLEnumValue<>("V2")];
                };
                description="descrEnum";
        },
        GQLField{
            name="withIntArg";
            type=gqlIntType;
            arguments = map({"intArg"->ArgumentDefinition(gqlIntType, Var("intVar"))});
            resolver=(v, m)=>m.get("intArg");
        }
    });

    value schema = Schema(queryRoot, null);
    //value doc = doci();
    value doc = inputTest();

    value rv = map({"fA"->5, "fC"->map({"sub1"->19, "sub2"->map({"subsub21"->6, "subsub22"->16})}), "nicks"->[map({"n1"->1}), map({"n1"->424}), map({"n1"-> 3})], "enum"->"5"});

    JsonObject vars = JsonObject({"intVar"->8});
    print(executeRequest(doc, null, vars, schema, rv));
}
Document inputTest()
{
    return Document([
        OperationDefinition(OperationType.query, [
            /*
            Field{"obj";
                arguments_=[
                    Argument("inpObj", map({"of1s1"->5}))//, "b"->"BBB", "c"->true}))
//                    Argument("inpObj", "k")
                ];
                selectionSet = [
                    Field("of1s1")
                ];
            },*/
            Field{"withIntArg";arguments_=[Argument("intArg", Var("intVar"))];}
        ],
        null,
            {
            "intVar" -> VariableDefinition(gqlIntType)
            })
    ]);
}
Document introType()
{
    return Document([
        OperationDefinition(OperationType.query, [
            Field{"__type";
                alias_="t1";
                arguments_=[
                    Argument("name", "Enum1")
                ];
                selectionSet = [
                    Field("kind"),
                    Field("name")
                ];
            },
            Field{"__type";
                alias_="t2";
                arguments_=[
                    Argument("name", "n")
                ];
                selectionSet = [
                    Field("kind"),
                    Field("name"),
                    Field("kind", "k")
                ];
            },
            Field{"__type";
                alias_="t2";
                arguments_=[
                    Argument("name", "n")
                ];
                selectionSet = [
                    Field("description"),
                    Field("name")
                ];
            }
        ])
    ]);
}
Document introSchema()
{
    return Document([
        OperationDefinition(OperationType.query, [
            Field{"__schema";
                selectionSet = [
                    Field{"types";
                        selectionSet = [
                            Field("kind"),
                            Field("name"),
                            Field("description"),
                            Field("fields", null, [Argument("includeDeprecated", true)], null, [
                                Field("name"),
                                Field("description"),
                                Field{"args";selectionSet=[
                                    Field("name"),
                                    Field("description"),
                                    Field("type"),
                                    Field("defaultValue")
                                ];},
                                Field("type", null, null, null, [
                                    Field("name"),
                                    Field("kind"),
                                    Field{"ofType";selectionSet=[Field("name")];}
                                ]),
                                Field("isDeprecated"),
                                Field("deprecationReason")
                            ]),
                            Field{"interfaces";selectionSet=[
                                Field("name")
                            ];},
                            Field{"possibleTypes";selectionSet=[
                                Field("name")
                            ];},
                            Field("enumValues", null, [Argument("includeDeprecated", false)], null, [
                                Field("name"),
                                Field("description"),
                                Field("isDeprecated"),
                                Field("deprecationReason")
                            ]),
                            Field{"inputFields";selectionSet=[
                                Field("name"),
                                Field("description"),
                                Field("type"),
                                Field("defaultValue")
                            ];},
                            Field{"ofType";}
                        ];
                    }
                ];
            }
        ])
    ]);
}

Document doci()
{
    value doc = Document([
        OperationDefinition{
                type = OperationType.query;
                selectionSet = [
                    Field{
                        name="fA";
                        selectionSet = [
                            Field("f2")
                        ];
                    },
                    Field{
                        name="fC";
                        selectionSet = [
                            Field("sub1"),
                            Field{
                                name="sub2";
                                selectionSet = [
                                    Field("subsub21"),
                                    Field("subsub22")
                                ];
                            }
                        ];
                    },
                    Field{
                        name="nicks";
                        selectionSet = [
                            Field("n1")
                        ];
                    },
                    Field{
                        name="enum";
                    }
                ];
        }]);
    return doc;
}

GQLObjectType simple = GQLObjectType("simple", {GQLField("f1", GQLNonNullType(gqlIntType)), GQLField("f2", gqlIntType)});