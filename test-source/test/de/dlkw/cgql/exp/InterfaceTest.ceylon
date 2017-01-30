import ceylon.logging {
    addLogWriter,
    writeSimpleLog
}
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
    FragmentDefinition,
    InlineFragment,
    FragmentSpread
}
import de.dlkw.graphql.exp.types {
    gqlIntType,
    GQLField,
    GQLObjectType,
    GQLInterfaceType,
    gqlStringType,
    GQLNonNullType
}
test
shared void implementsAll() {
    addLogWriter(writeSimpleLog);

    value iface1 = GQLInterfaceType("if1", {
        GQLField("f1", gqlStringType),
        GQLField{"f2"; gqlIntType;}
    });
    value iface2 = GQLInterfaceType("if2", {
        GQLField("f1", gqlStringType),
        GQLField("f3", gqlIntType)
    });

    value queryRoot = GQLObjectType("QueryRoot", {
        GQLField {
            name = "f1";
                    gqlStringType;
            //resolver = (a, e) => 5;
        },
    GQLField{"f2"; gqlIntType;},
    GQLField("f3", gqlIntType),
    GQLField("f4", gqlIntType)
    },
        { iface1, iface2 });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value document2 = Document([FragmentDefinition("frag1", [Field("f4")], "QueryRoot"), OperationDefinition(OperationType.query, [InlineFragment([Field("f1")]), FragmentSpread("frag1")])]);

    value result = schema.executeRequest(document2, null, map({"f1"->"s"}));

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assertNull(result.errors);

    assertEquals(data.size, 1);
    assert (is String f1 = data["f1"]);
    assertEquals(f1, "s");
}
