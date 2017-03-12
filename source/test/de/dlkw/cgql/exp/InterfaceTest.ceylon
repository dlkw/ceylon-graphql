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
    FragmentSpread,
    Selection
}
import de.dlkw.graphql.exp.types {
    gqlIntType,
    GQLField,
    GQLObjectType,
    GQLInterfaceType,
    gqlStringType,
    GQLNonNullType,
    TypeResolver,
    GQLAbstractType
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

    value result = schema.executeRequest(document2, null, null, map({"f1"->"s"}));

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assertNull(result.errors);

    assertEquals(data.size, 1);
    assert (is String f1 = data["f1"]);
    assertEquals(f1, "s");
}

test
shared void implementingOtherType() {
    addLogWriter(writeSimpleLog);

    value iface1 = GQLInterfaceType("if1", {
        GQLField("i1", gqlStringType)
    });

    value queryRoot = GQLObjectType("QueryRoot", {
        GQLField {
            name = "f1";
                    iface1;
        }
    });

    value otherType = GQLObjectType("OtherType", { GQLField{name="i1";type=gqlStringType;}, GQLField{name="o2";type=gqlIntType;}}, {iface1});

    object typeResolver satisfies TypeResolver
    {
        shared actual {GQLObjectType*} knownTypes => [otherType];

        shared actual String? resolveAbstractType(GQLAbstractType abstractType, Object objectValue) => "OtherType";
    }

    value schema = Schema(queryRoot, null, [typeResolver]);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1", null, null, null, null, [Field("i1"), InlineFragment([Field("o2")], null, "OtherType")])])]);

    value result = schema.executeRequest(document, null, null, map({"f1"->map({"i1"->"s", "o2"->5})}));

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assertNull(result.errors);

    assertEquals(data.size, 1);
    assert (is Map<Anything, Anything> f1 = data["f1"]);
    assertEquals(f1.size, 2);
    assert (is String i1 = f1["i1"]);
    assert (i1 == "s");
    assert (is Integer o2 = f1["o2"]);
    assert (o2 == 5);
}
