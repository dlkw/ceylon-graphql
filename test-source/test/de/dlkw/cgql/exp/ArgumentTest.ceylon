import ceylon.test {
    test,
    assertEquals,
    assertTrue,
    assertNull
}

import de.dlkw.graphql.exp {
    GQLObjectType,
    GQLField,
    GQLIntType,
    Document,
    Schema,
    OperationDefinition,
    Field,
    OperationType,
    GQLIntValue,
    ResolvingError,
    GQLNonNullType,
    FieldNullError,
    ArgumentDefinition,
    undefined,
    Argument
}

test
shared void intArgumentWithIntValue() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
            type = GQLIntType();
            arguments = map({
                "arg1"->ArgumentDefinition(GQLIntType(), GQLIntValue(99))
            });
            resolver = (a, e) => e["arg1"]?. value_;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1", null, [Argument("arg1", 88)])])]);

    value result = schema.executeRequest(document);
    assertTrue(result.includedExecution);

    assert (exists data = result.data);
    assertTrue(data.value_.defines("f1"));
    assert (is GQLIntValue f1 = data.value_["f1"]);
    assertEquals(f1.value_, 88);
}

test
shared void intArgumentWithIntDefault() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
            type = GQLIntType();
            arguments = map({
                "arg1"->ArgumentDefinition(GQLIntType(), GQLIntValue(99))
            });
            resolver = (a, e) => e["arg1"]?. value_;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.executeRequest(document);
    assertTrue(result.includedExecution);

    assert (exists data = result.data);
    assertTrue(data.value_.defines("f1"));
    assert (is GQLIntValue f1 = data.value_["f1"]);
    assertEquals(f1.value_, 99);
}

test
shared void intArgumentWithNullDefault() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
            type = GQLIntType();
            arguments = map({
                "arg1"->ArgumentDefinition(GQLIntType(), null)
            });
            resolver = (a, e) => e["arg1"]?. value_;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.executeRequest(document);
    assertTrue(result.includedExecution);

    assert (exists data = result.data);
    assertTrue(data.value_.defines("f1"));
    assert (is Null f1 = data.value_["f1"]);
}

test
shared void intArgumentWithoutDefault() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
            type = GQLIntType();
            arguments = map({
                "arg1"->ArgumentDefinition(GQLIntType(), undefined)
            });
            resolver = (a, e) => e["arg1"]?. value_;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.executeRequest(document);
    assertTrue(result.includedExecution);

    assert (exists data = result.data);
    assertTrue(data.value_.defines("f1"));
    assert (is Null f1 = data.value_["f1"]);
}
