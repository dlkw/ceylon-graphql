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
    ArgumentDefinition
}

test
shared void intArgumentTest() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
            type = GQLIntType();
            arguments = map({
                "arg1"->ArgumentDefinition(GQLIntType(), GQLIntValue(99))
            });
            resolver = (a, e) => e["arg1"];
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.executeRequest(document);
    assertTrue(result.includedExecution);
}
