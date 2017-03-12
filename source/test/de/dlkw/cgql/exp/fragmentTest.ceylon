import ceylon.logging {
    addLogWriter,
    writeSimpleLog
}
import ceylon.test {
    test
}

import de.dlkw.graphql.exp {
    OperationDefinition,
    Field,
    OperationType,
    Document,
    Schema,
    FragmentDefinition,
    FragmentSpread
}
import de.dlkw.graphql.exp.types {
    gqlIntType,
    GQLField,
    GQLObjectType,
    GQLTypeReference
}

test
shared void testNestedFragmentForbidden() {
    addLogWriter(writeSimpleLog);
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
                    gqlIntType;
            //resolver = (a, e) => 5;
        },
        GQLField {
            name = "f2";
            GQLTypeReference("queryRoot");
        }})
    ;

    value schema = Schema(queryRoot, null);

    value document = Document([FragmentDefinition(
        "frag1",
        [Field("f1"),
            Field("f2", null, null, null, null, [FragmentSpread("frag1")])
        ],
        null
    ), OperationDefinition(OperationType.query, [FragmentSpread("frag1")
    ])]);

    value ff0 = map({ "f1"->0 });
    value ff1 = map({ "f1"->1, "f2"->ff0 });
    value ff2 = map({ "f1"->2, "f2"->ff1 });
    value ff3 = map({ "f1"->3, "f2"->ff2 });
    value result = schema.executeRequest(document, null, null, ff3);
    print(result.data);
    print(result.errors);
    assert (exists errors = result.errors);
    assert (!errors.empty);
}
