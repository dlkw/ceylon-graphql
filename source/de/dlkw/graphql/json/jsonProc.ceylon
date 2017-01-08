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
    Argument
}
import de.dlkw.graphql.exp.types {
    GQLNonNullType,
    gqlIntType,
    GQLListType,
    GQLEnumType,
    GQLEnumValue,
    GQLField,
    GQLObjectType
}

JsonObject exe(Document doc, Schema schema, Anything rootValue)
{
    value res = schema.executeRequest(doc, null, rootValue);
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
            "fA";
            gqlIntType;
            "descA";
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
        GQLField("nicks", GQLNonNullType(GQLListType(GQLNonNullType(GQLObjectType{
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
                        GQLEnumValue{"V1";"5";"descr";true;"Deprecation Reason";},
                        GQLEnumValue("V2")
                };
                description="descrEnum";
        }
    });

    value schema = Schema(queryRoot, null);
    //value doc = doci();
    value doc = intro();

    value rv = map({"fA"->5, "fC"->map({"sub1"->19, "sub2"->map({"subsub21"->6, "subsub22"->16})}), "nicks"->[map({"n1"->1}), map({"n1"->424}), map({"n1"-> 3})], "enum"->"5"});
    print(exe(doc, schema, rv));
}
Document intro()
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
                            Field("enumValues", null, [Argument("includeDeprecated", true)], null, [
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