import ceylon.test {
    test,
    assertEquals,
    assertTrue,
    assertNull
}

import de.dlkw.graphql.exp {
    Document,
    Schema,
    OperationDefinition,
    Field,
    OperationType,
    ResolutionError,
    FieldNullError
}
import de.dlkw.graphql.exp.types {
    GQLObjectType,
    GQLField,
    gqlIntType,
    GQLNonNullType
}
import ceylon.logging {
    addLogWriter,
    writeSimpleLog
}

test
shared void singleIntMayBeNullAndIsNotNull() {
    addLogWriter(writeSimpleLog);
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
                    gqlIntType;
            //resolver = (a, e) => 5;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.executeRequest(document, null, null, map({"f1"->5}));

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assertNull(result.errors);

    assertEquals(data.size, 1);
    assert (is Integer f1 = data["f1"]);
    assertEquals(f1, 5);
}

test
shared void singleIntMayBeNullAndIsNull() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
                    gqlIntType;
            resolver = (a, e) => null;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.executeRequest(document);

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assertNull(result.errors);

    assertEquals(data.size, 1);
    assertTrue(data.defines("f1"));
    assert (is Null f1 = data["f1"]);
}

test
shared void singleIntMayBeNullAndIsError() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
                    gqlIntType;
            resolver = (a, e) => 5 / 0;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.executeRequest(document);

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assertEquals(data.size, 1);
    assertTrue(data.defines("f1"));
    assert (is Null f1 = data["f1"]);

    assert (exists errors = result.errors);
    assertEquals(errors.size, 1);
    assert (is ResolutionError error = errors[0]);
    assertEquals(error.stringPath, "f1");
}

test
shared void singleIntMayNotBeNullAndIsNotNull() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
            type = GQLNonNullType(gqlIntType);
            resolver = (a, e) => 5;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.executeRequest(document);

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assertNull(result.errors);

    assertEquals(data.size, 1);
    assert (is Integer f1 = data["f1"]);
    assertEquals(f1, 5);
}

test
shared void singleIntMayNotBeNullAndIsNull() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
            type = GQLNonNullType(gqlIntType);
            resolver = (a, e) => null;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.executeRequest(document);

    assertTrue(result.includedExecution);
    assertNull(result.data);
    assert (exists errors = result.errors);
    assertEquals(errors.size, 1);
    assert (is FieldNullError error = errors[0]);
    assertEquals(error.stringPath, "f1");
}

test
shared void singleIntMayNotBeNullAndIsError() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
            type = GQLNonNullType(gqlIntType);
            resolver = (a, e) => 5 / 0;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.executeRequest(document);

    assertTrue(result.includedExecution);
    assertNull(result.data);

    assert (exists errors = result.errors);
    assertEquals(errors.size, 1);
    assert (is ResolutionError error = errors[0]);
    assertEquals(error.stringPath, "f1");
}



test
shared void withNonNullBeforeAndAfterIntMayBeNullAndIsNotNull() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f0";
            type = gqlIntType;
            resolver = (a, e) => 0;
        },
        GQLField {
            name = "f1";
            type = gqlIntType;
            resolver = (a, e) => 5;
        },
        GQLField {
            name = "f2";
            type = gqlIntType;
            resolver = (a, e) => 2;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f0"), Field("f1"), Field("f2")])]);

    value result = schema.executeRequest(document);

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assertNull(result.errors);

    assertEquals(data.size, 3);
    assert (is Integer f0 = data["f0"]);
    assertEquals(f0, 0);
    assert (is Integer f1 = data["f1"]);
    assertEquals(f1, 5);
    assert (is Integer f2 = data["f2"]);
    assertEquals(f2, 2);
}

test
shared void withNonNullBeforeAndAfterIntMayBeNullAndIsNull() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f0";
            type = gqlIntType;
            resolver = (a, e) => 0;
        },
        GQLField {
            name = "f1";
            type = gqlIntType;
            resolver = (a, e) => null;
        },
        GQLField {
            name = "f2";
            type = gqlIntType;
            resolver = (a, e) => 2;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f0"), Field("f1"), Field("f2")])]);

    value result = schema.executeRequest(document);

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assertNull(result.errors);

    assertEquals(data.size, 3);
    assert (is Integer f0 = data["f0"]);
    assertEquals(f0, 0);
    assertTrue(data.defines("f1"));
    assert (is Null f1 = data["f1"]);
    assert (is Integer f2 = data["f2"]);
    assertEquals(f2, 2);
}

test
shared void withNonNullBeforeAndAfterIntMayBeNullAndIsError() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f0";
            type = gqlIntType;
            resolver = (a, e) => 0;
        },
        GQLField {
            name = "f1";
            type = gqlIntType;
            resolver = (a, e) => 5/0;
        },
        GQLField {
            name = "f2";
            type = gqlIntType;
            resolver = (a, e) => 2;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f0"), Field("f1"), Field("f2")])]);

    value result = schema.executeRequest(document);

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assertEquals(data.size, 3);
    assert (is Integer f0 = data["f0"]);
    assertEquals(f0, 0);
    assertTrue(data.defines("f1"));
    assert (is Null f1 = data["f1"]);
    assert (is Integer f2 = data["f2"]);
    assertEquals(f2, 2);

    assert (exists errors = result.errors);
    assertEquals(errors.size, 1);
    assert (is ResolutionError error = errors[0]);
    assertEquals(error.stringPath, "f1");
}

test
shared void withNonNullBeforeAndAfterIntMayNotBeNullAndIsNotNull() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f0";
            type = gqlIntType;
            resolver = (a, e) => 0;
        },
        GQLField {
            name = "f1";
            type = GQLNonNullType(gqlIntType);
            resolver = (a, e) => 5;
        },
        GQLField {
            name = "f2";
            type = gqlIntType;
            resolver = (a, e) => 2;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f0"), Field("f1"), Field("f2")])]);

    value result = schema.executeRequest(document);

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assertNull(result.errors);

    assertEquals(data.size, 3);
    assert (is Integer f0 = data["f0"]);
    assertEquals(f0, 0);
    assert (is Integer f1 = data["f1"]);
    assertEquals(f1, 5);
    assert (is Integer f2 = data["f2"]);
    assertEquals(f2, 2);
}

test
shared void withNonNullBeforeAndAfterIntMayNotBeNullAndIsNull() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f0";
            type = gqlIntType;
            resolver = (a, e) => 0;
        },
        GQLField {
            name = "f1";
            type = GQLNonNullType(gqlIntType);
            resolver = (a, e) => null;
        },
        GQLField {
            name = "f2";
            type = gqlIntType;
            resolver = (a, e) => 2;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f0"), Field("f1"), Field("f2")])]);

    value result = schema.executeRequest(document);

    assertTrue(result.includedExecution);
    assertNull(result.data);

    assert (exists errors = result.errors);
    assertEquals(errors.size, 1);
    assert (is FieldNullError error = errors[0]);
    assertEquals(error.stringPath, "f1");
}

test
shared void withNonNullBeforeAndAfterIntMayNotBeNullAndIsError() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f0";
            type = gqlIntType;
            resolver = (a, e) => 0;
        },
        GQLField {
            name = "f1";
            type = GQLNonNullType(gqlIntType);
            resolver = (a, e) => 5/0;
        },
        GQLField {
            name = "f2";
            type = gqlIntType;
            resolver = (a, e) => 2;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f0"), Field("f1"), Field("f2")])]);

    value result = schema.executeRequest(document);

    assertTrue(result.includedExecution);
    assertNull(result.data);

    assert (exists errors = result.errors);
    assertEquals(errors.size, 1);
    assert (is ResolutionError error = errors[0]);
    assertEquals(error.stringPath, "f1");
}

test
shared void withErrorsBeforeAndAfterIntMayNotBeNullAndIsNotNull() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f0";
            type = gqlIntType;
            resolver = (a, e) => 1/0;
        },
        GQLField {
            name = "f1";
            type = GQLNonNullType(gqlIntType);
            resolver = (a, e) => 5;
        },
        GQLField {
            name = "f2";
            type = gqlIntType;
            resolver = (a, e) => 2/0;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f0"), Field("f1"), Field("f2")])]);

    value result = schema.executeRequest(document);

    assertTrue(result.includedExecution);
    assert (exists data = result.data);

    assertEquals(data.size, 3);
    assertTrue(data.defines("f0"));
    assert (is Null f0 = data["f0"]);
    assert (is Integer f1 = data["f1"]);
    assertEquals(f1, 5);
    assertTrue(data.defines("f2"));
    assert (is Null f2 = data["f2"]);

    assert (exists errors = result.errors);
    assertEquals(errors.size, 2);
    assert (is ResolutionError error0 = errors[0]);
    assertEquals(error0.stringPath, "f0");
    assert (is ResolutionError error1 = errors[1]);
    assertEquals(error1.stringPath, "f2");
}

test
shared void withErrorsBeforeAndAfterIntMayNotBeNullAndIsNull() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f0";
            type = gqlIntType;
            resolver = (a, e) => 1/0;
        },
        GQLField {
            name = "f1";
            type = GQLNonNullType(gqlIntType);
            resolver = (a, e) => null;
        },
        GQLField {
            name = "f2";
            type = gqlIntType;
            resolver = (a, e) => 2/0;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f0"), Field("f1"), Field("f2")])]);

    value result = schema.executeRequest(document);

    assertTrue(result.includedExecution);
    assertNull(result.data);

    assert (exists errors = result.errors);
    assertEquals(errors.size, 3);
    assert (is ResolutionError error0 = errors[0]);
    assertEquals(error0.stringPath, "f0");
    assert (is FieldNullError error1 = errors[1]);
    assertEquals(error1.stringPath, "f1");
    assert (is ResolutionError error2 = errors[2]);
    assertEquals(error2.stringPath, "f2");
}

test
shared void withErrorsBeforeAndAfterIntMayBeNullAndIsError() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f0";
            type = gqlIntType;
            resolver = (a, e) => 1/0;
        },
        GQLField {
            name = "f1";
            type = gqlIntType;
            resolver = (a, e) => 5/0;
        },
        GQLField {
            name = "f2";
            type = gqlIntType;
            resolver = (a, e) => 2/0;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f0"), Field("f1"), Field("f2")])]);

    value result = schema.executeRequest(document);

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assertEquals(data.size, 3);
    assertTrue(data.defines("f0"));
    assertTrue(data.defines("f1"));
    assertTrue(data.defines("f2"));
    assertNull(data["f0"]);
    assertNull(data["f1"]);
    assertNull(data["f2"]);

    assert (exists errors = result.errors);
    assertEquals(errors.size, 3);
    assert (is ResolutionError error0 = errors[0]);
    assertEquals(error0.stringPath, "f0");
    assert (is ResolutionError error1 = errors[1]);
    assertEquals(error1.stringPath, "f1");
    assert (is ResolutionError error2 = errors[2]);
    assertEquals(error2.stringPath, "f2");
}
