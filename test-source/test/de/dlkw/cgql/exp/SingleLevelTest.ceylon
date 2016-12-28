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
    FieldNullError
}

test
shared void singleIntMayBeNullAndIsNotNull() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
                    GQLIntType();
            resolver = (a, e) => 5;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.execute(document);

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assertNull(result.errors);

    assertEquals(data.value_.size, 1);
    assert (is GQLIntValue f1 = data.value_["f1"]);
    assertEquals(f1.value_, 5);
}

test
shared void singleIntMayBeNullAndIsNull() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
                    GQLIntType();
            resolver = (a, e) => null;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.execute(document);

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assertNull(result.errors);

    assertEquals(data.value_.size, 1);
    assertTrue(data.value_.defines("f1"));
    assert (is Null f1 = data.value_["f1"]);
}

test
shared void singleIntMayBeNullAndIsError() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
                    GQLIntType();
            resolver = (a, e) => 5 / 0;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.execute(document);

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assertEquals(data.value_.size, 1);
    assertTrue(data.value_.defines("f1"));
    assert (is Null f1 = data.value_["f1"]);

    assert (exists errors = result.errors);
    assertEquals(errors.size, 1);
    assert (is ResolvingError error = errors[0]);
    assertEquals(error.stringPath, "f1");
}

test
shared void singleIntMayNotBeNullAndIsNotNull() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
            type = GQLNonNullType(GQLIntType());
            resolver = (a, e) => 5;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.execute(document);

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assertNull(result.errors);

    assertEquals(data.value_.size, 1);
    assert (is GQLIntValue f1 = data.value_["f1"]);
    assertEquals(f1.value_, 5);
}

test
shared void singleIntMayNotBeNullAndIsNull() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f1";
            type = GQLNonNullType(GQLIntType());
            resolver = (a, e) => null;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.execute(document);

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
            type = GQLNonNullType(GQLIntType());
            resolver = (a, e) => 5 / 0;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f1")])]);

    value result = schema.execute(document);

    assertTrue(result.includedExecution);
    assertNull(result.data);

    assert (exists errors = result.errors);
    assertEquals(errors.size, 1);
    assert (is ResolvingError error = errors[0]);
    assertEquals(error.stringPath, "f1");
}



test
shared void withNonNullBeforeAndAfterIntMayBeNullAndIsNotNull() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f0";
            type = GQLIntType();
            resolver = (a, e) => 0;
        },
        GQLField {
            name = "f1";
            type = GQLIntType();
            resolver = (a, e) => 5;
        },
        GQLField {
            name = "f2";
            type = GQLIntType();
            resolver = (a, e) => 2;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f0"), Field("f1"), Field("f2")])]);

    value result = schema.execute(document);

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assertNull(result.errors);

    assertEquals(data.value_.size, 3);
    assert (is GQLIntValue f0 = data.value_["f0"]);
    assertEquals(f0.value_, 0);
    assert (is GQLIntValue f1 = data.value_["f1"]);
    assertEquals(f1.value_, 5);
    assert (is GQLIntValue f2 = data.value_["f2"]);
    assertEquals(f2.value_, 2);
}

test
shared void withNonNullBeforeAndAfterIntMayBeNullAndIsNull() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f0";
            type = GQLIntType();
            resolver = (a, e) => 0;
        },
        GQLField {
            name = "f1";
            type = GQLIntType();
            resolver = (a, e) => null;
        },
        GQLField {
            name = "f2";
            type = GQLIntType();
            resolver = (a, e) => 2;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f0"), Field("f1"), Field("f2")])]);

    value result = schema.execute(document);

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assertNull(result.errors);

    assertEquals(data.value_.size, 3);
    assert (is GQLIntValue f0 = data.value_["f0"]);
    assertEquals(f0.value_, 0);
    assertTrue(data.value_.defines("f1"));
    assert (is Null f1 = data.value_["f1"]);
    assert (is GQLIntValue f2 = data.value_["f2"]);
    assertEquals(f2.value_, 2);
}

test
shared void withNonNullBeforeAndAfterIntMayBeNullAndIsError() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f0";
            type = GQLIntType();
            resolver = (a, e) => 0;
        },
        GQLField {
            name = "f1";
            type = GQLIntType();
            resolver = (a, e) => 5/0;
        },
        GQLField {
            name = "f2";
            type = GQLIntType();
            resolver = (a, e) => 2;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f0"), Field("f1"), Field("f2")])]);

    value result = schema.execute(document);

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assertEquals(data.value_.size, 3);
    assert (is GQLIntValue f0 = data.value_["f0"]);
    assertEquals(f0.value_, 0);
    assertTrue(data.value_.defines("f1"));
    assert (is Null f1 = data.value_["f1"]);
    assert (is GQLIntValue f2 = data.value_["f2"]);
    assertEquals(f2.value_, 2);

    assert (exists errors = result.errors);
    assertEquals(errors.size, 1);
    assert (is ResolvingError error = errors[0]);
    assertEquals(error.stringPath, "f1");
}

test
shared void withNonNullBeforeAndAfterIntMayNotBeNullAndIsNotNull() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f0";
            type = GQLIntType();
            resolver = (a, e) => 0;
        },
        GQLField {
            name = "f1";
            type = GQLNonNullType(GQLIntType());
            resolver = (a, e) => 5;
        },
        GQLField {
            name = "f2";
            type = GQLIntType();
            resolver = (a, e) => 2;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f0"), Field("f1"), Field("f2")])]);

    value result = schema.execute(document);

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assertNull(result.errors);

    assertEquals(data.value_.size, 3);
    assert (is GQLIntValue f0 = data.value_["f0"]);
    assertEquals(f0.value_, 0);
    assert (is GQLIntValue f1 = data.value_["f1"]);
    assertEquals(f1.value_, 5);
    assert (is GQLIntValue f2 = data.value_["f2"]);
    assertEquals(f2.value_, 2);
}

test
shared void withNonNullBeforeAndAfterIntMayNotBeNullAndIsNull() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f0";
            type = GQLIntType();
            resolver = (a, e) => 0;
        },
        GQLField {
            name = "f1";
            type = GQLNonNullType(GQLIntType());
            resolver = (a, e) => null;
        },
        GQLField {
            name = "f2";
            type = GQLIntType();
            resolver = (a, e) => 2;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f0"), Field("f1"), Field("f2")])]);

    value result = schema.execute(document);

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
            type = GQLIntType();
            resolver = (a, e) => 0;
        },
        GQLField {
            name = "f1";
            type = GQLNonNullType(GQLIntType());
            resolver = (a, e) => 5/0;
        },
        GQLField {
            name = "f2";
            type = GQLIntType();
            resolver = (a, e) => 2;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f0"), Field("f1"), Field("f2")])]);

    value result = schema.execute(document);

    assertTrue(result.includedExecution);
    assertNull(result.data);

    assert (exists errors = result.errors);
    assertEquals(errors.size, 1);
    assert (is ResolvingError error = errors[0]);
    assertEquals(error.stringPath, "f1");
}

test
shared void withErrorsBeforeAndAfterIntMayNotBeNullAndIsNotNull() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f0";
            type = GQLIntType();
            resolver = (a, e) => 1/0;
        },
        GQLField {
            name = "f1";
            type = GQLNonNullType(GQLIntType());
            resolver = (a, e) => 5;
        },
        GQLField {
            name = "f2";
            type = GQLIntType();
            resolver = (a, e) => 2/0;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f0"), Field("f1"), Field("f2")])]);

    value result = schema.execute(document);

    assertTrue(result.includedExecution);
    assert (exists data = result.data);

    assertEquals(data.value_.size, 3);
    assertTrue(data.value_.defines("f0"));
    assert (is Null f0 = data.value_["f0"]);
    assert (is GQLIntValue f1 = data.value_["f1"]);
    assertEquals(f1.value_, 5);
    assertTrue(data.value_.defines("f2"));
    assert (is Null f2 = data.value_["f2"]);

    assert (exists errors = result.errors);
    assertEquals(errors.size, 2);
    assert (is ResolvingError error0 = errors[0]);
    assertEquals(error0.stringPath, "f0");
    assert (is ResolvingError error1 = errors[1]);
    assertEquals(error1.stringPath, "f2");
}

test
shared void withErrorsBeforeAndAfterIntMayNotBeNullAndIsNull() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f0";
            type = GQLIntType();
            resolver = (a, e) => 1/0;
        },
        GQLField {
            name = "f1";
            type = GQLNonNullType(GQLIntType());
            resolver = (a, e) => null;
        },
        GQLField {
            name = "f2";
            type = GQLIntType();
            resolver = (a, e) => 2/0;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f0"), Field("f1"), Field("f2")])]);

    value result = schema.execute(document);

    assertTrue(result.includedExecution);
    assertNull(result.data);

    assert (exists errors = result.errors);
    assertEquals(errors.size, 3);
    assert (is ResolvingError error0 = errors[0]);
    assertEquals(error0.stringPath, "f0");
    assert (is FieldNullError error1 = errors[1]);
    assertEquals(error1.stringPath, "f1");
    assert (is ResolvingError error2 = errors[2]);
    assertEquals(error2.stringPath, "f2");
}

test
shared void withErrorsBeforeAndAfterIntMayBeNullAndIsError() {
    value queryRoot = GQLObjectType("queryRoot", {
        GQLField {
            name = "f0";
            type = GQLIntType();
            resolver = (a, e) => 1/0;
        },
        GQLField {
            name = "f1";
            type = GQLIntType();
            resolver = (a, e) => 5/0;
        },
        GQLField {
            name = "f2";
            type = GQLIntType();
            resolver = (a, e) => 2/0;
        }
    });

    value schema = Schema(queryRoot, null);

    value document = Document([OperationDefinition(OperationType.query, [Field("f0"), Field("f1"), Field("f2")])]);

    value result = schema.execute(document);

    assertTrue(result.includedExecution);
    assert (exists data = result.data);
    assertEquals(data.value_.size, 3);
    assertTrue(data.value_.defines("f0"));
    assertTrue(data.value_.defines("f1"));
    assertTrue(data.value_.defines("f2"));
    assertNull(data.value_["f0"]);
    assertNull(data.value_["f1"]);
    assertNull(data.value_["f2"]);

    assert (exists errors = result.errors);
    assertEquals(errors.size, 3);
    assert (is ResolvingError error0 = errors[0]);
    assertEquals(error0.stringPath, "f0");
    assert (is ResolvingError error1 = errors[1]);
    assertEquals(error1.stringPath, "f1");
    assert (is ResolvingError error2 = errors[2]);
    assertEquals(error2.stringPath, "f2");
}
