import ceylon.json {
    JsonObject,
    Value,
    JsonArray
}
import de.dlkw.graphql.exp {
    Document,
    Schema,
    GQLObjectValue,
    Result,
    GQLIntValue,
    GQLListValue,
    GQLListType,
    GQLObjectType,
    GQLIntType,
    GQLNonNullType,
    GQLField,
    OperationDefinition,
    Field,
    OperationType,
    GQLEnumType,
    GQLEnumValue,
    GQLStringValue,
    FieldError
}

JsonObject exe(Document doc, Schema schema, Anything rootValue)
{
    value res = schema.execute(doc, null, rootValue);
    if (res.includedExecution) {
        if (exists errors = res.errors) {
            return JsonObject({"data" -> mkJsonObject(res.data), "errors"->mkJsonErrors(errors)});
        }
        return JsonObject({"data" -> mkJsonObject(res.data)});
    }
    assert (exists errors = res.errors);
    return JsonObject({"errors" -> mkJsonErrors(errors)});
}

JsonObject? mkJsonObject(GQLObjectValue? gqlValue)
    => if (exists gqlValue) then JsonObject(gqlValue.value_.map((key->item) => key->mkJsonValue(item))) else null;

Value mkJsonValue(Result? gqlValue)
{
    switch (gqlValue)
    case (is Null) {
        return null;
    }
    case (is GQLIntValue) {
        return gqlValue.value_;
    }
    case (is GQLStringValue) {
        return gqlValue.value_;
    }
    case (is GQLObjectValue) {
        return mkJsonObject(gqlValue);
    }
    case (is GQLListValue<Result>) {
        return JsonArray(gqlValue.elements.map((element) => mkJsonValue(element)));
    }
    else {
        throw;
    }
}

JsonArray mkJsonErrors({FieldError*} errors)
    => JsonArray(errors.map((error)=>JsonObject({"message"->"not yet","location"->null,"path"->error.stringPath})));

shared void run()
{
    variable Integer aa = 0;
    value queryRoot = GQLObjectType("n", {
        GQLField{
                    "fA";
                    GQLIntType();
                    "descA";
        },
        GQLField{
            name="fB";
            type=GQLNonNullType(GQLIntType());
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
                    type=GQLIntType();
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
                                type=GQLIntType();
                                resolver=(a, b){return 5/0;};
                            },
                            GQLField{
                                name="subsub22";
//                                type=GQLNonNullType(GQLIntType());
                                type=GQLIntType();
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
                type=GQLNonNullType(GQLIntType());
//                type=GQLIntType();
                resolver=(a, b){return if (++aa%2==0) then 5/0 else aa;};
            }};
        }))), "descNicks"),
        GQLField{
                name="enum";
                type=GQLEnumType{
                        GQLEnumValue{"V1";"5";"descr";true;"Deprecation Reason";},
                        GQLEnumValue("V2")
                };
                description="descrEnum";
        }
    });

    value schema = Schema(queryRoot, null);
    value doc = doci();

    value rv = map({"fA"->5, "fC"->map({"sub1"->19, "sub2"->map({"subsub21"->6, "subsub22"->16})}), "nicks"->[map({"n1"->1}), map({"n1"->424}), map({"n1"-> 3})], "enum"->"5"});
    print(exe(doc, schema, rv));
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