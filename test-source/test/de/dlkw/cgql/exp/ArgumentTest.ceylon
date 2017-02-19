import ceylon.test {
    test,
    assertEquals,
    assertTrue
}

import de.dlkw.graphql.exp {
    Document,
    Schema,
    OperationDefinition,
    Field,
    OperationType,
    Argument,
    VariableDefinition,
    Var
}
import de.dlkw.graphql.exp.types {
    GQLObjectType,
    GQLField,
    gqlIntType,
    undefined,
    ArgumentDefinition
}

test
shared void intArgumentWithIntValue() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
            type = gqlIntType;
            arguments = map({
                "arg1"->ArgumentDefinition(gqlIntType, 99)
            });
            resolver = (a, e) => e["arg1"];
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1", null, [Argument("arg1", 88)])])]);

    value result = schema.executeRequest(document);
    assertTrue(result.includedExecution);

    assert (exists data = result.data);
    assertTrue(data.defines("f1"));
    assert (is Integer f1 = data["f1"]);
    assertEquals(f1, 88);
}

test
shared void intArgumentWithIntDefault() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
            type = gqlIntType;
            arguments = map({
                "arg1"->ArgumentDefinition(gqlIntType, 99)
            });
            resolver = (a, e) => e["arg1"];
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.executeRequest(document);
    assertTrue(result.includedExecution);

    assert (exists data = result.data);
    assertTrue(data.defines("f1"));
    assert (is Integer f1 = data["f1"]);
    assertEquals(f1, 99);
}

test
shared void intArgumentWithNullDefault() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
            type = gqlIntType;
            arguments = map({
                "arg1"->ArgumentDefinition(gqlIntType, null)
            });
            resolver = (a, e) => e["arg1"];
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.executeRequest(document);
    assertTrue(result.includedExecution);

    assert (exists data = result.data);
    assertTrue(data.defines("f1"));
    assert (is Null f1 = data["f1"]);
}

test
shared void intArgumentWithoutDefault() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
            type = gqlIntType;
            arguments = map({
                "arg1"->ArgumentDefinition(gqlIntType, undefined)
            });
            resolver = (a, e) => e["arg1"];
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.executeRequest(document);
    assertTrue(result.includedExecution);

    assert (exists data = result.data);
    assertTrue(data.defines("f1"));
    assert (is Null f1 = data["f1"]);
}

test
shared void intArgumentWithVariable() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
            type = gqlIntType;
            arguments = map({
                "arg1"->ArgumentDefinition(gqlIntType, undefined)
            });
            resolver = (a, e) => e["arg1"];
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1", null, [Argument("arg1", Var("var1"))])], null,
        {"var1"->VariableDefinition(gqlIntType, 3)}
    )]);

    value result = schema.executeRequest(document);
    assertTrue(result.includedExecution);

    assert (exists data = result.data);
    assertTrue(data.defines("f1"));
    assert (is Integer f1 = data["f1"]);
    assertEquals(f1, 3);
}
