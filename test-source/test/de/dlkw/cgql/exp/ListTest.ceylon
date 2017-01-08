import ceylon.test {
    assertNull,
    assertEquals,
    assertTrue,
    test
}
import de.dlkw.graphql.exp {
    OperationDefinition,
    Field,
    OperationType,
    Document,
    Schema,
    ResolvedNotIterableError,
    FieldNullError,
    ListCompletionError
}
import ceylon.logging {
    addLogWriter,
    writeSimpleLog
}
import de.dlkw.graphql.exp.types {
    GQLObjectType,
    GQLField,
    GQLListType,
    gqlIntType,
    GQLNonNullType
}

test
shared void listWithIntNotIterable() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
            type = GQLListType(gqlIntType);
            resolver = (a, e) => 5;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.executeRequest(document);


    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assert (exists errors = result.errors);

    assertEquals(data.size, 1);
    assert (is Null f1 = data["f1"]);

    assertEquals(errors.size, 1);
    assert (is ResolvedNotIterableError error0 = errors[0]);
    assertEquals(error0.stringPath, "f1");
}

test
shared void listWithNullableIntsAreNotNull() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
            type = GQLListType(gqlIntType);
            resolver = (a, e) => [5, 6];
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.executeRequest(document);

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assertNull(result.errors);

    assertEquals(data.size, 1);
    assert (is Anything[] f1 = data["f1"]);
    assertEquals(f1.size, 2);
    assert (is Integer el0 = f1[0]);
    assertEquals(el0, 5);
    assert (is Integer el1 = f1[1]);
    assertEquals(el1, 6);
}

test
shared void listWithNullableIntsIsErrorNonNull() {
    addLogWriter(writeSimpleLog);
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
            type = GQLListType(gqlIntType);
            resolver = (a, e) => {5/0, 6};
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.executeRequest(document);

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assert (exists errors = result.errors);

    assertEquals(data.size, 1);
    assertTrue(data.defines("f1"));
    assert (is Null f1 = data["f1"]);

    assertEquals(errors.size, 1);
    assert (is ListCompletionError error0 = errors[0]);
    assertEquals(error0.stringPath, "f1");
}

test
shared void listWithNonNullIntsIsNullNonNull() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
            type = GQLListType(GQLNonNullType(gqlIntType));
            resolver = (a, e) => [null, 6];
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.executeRequest(document);

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assert (exists errors = result.errors);

    assertEquals(data.size, 1);
    assert (is Null f1 = data["f1"]);

    assertEquals(errors.size, 1);
    assert (is FieldNullError error0 = errors[0]);
    assertEquals(error0.stringPath, "f1[0]");
}
