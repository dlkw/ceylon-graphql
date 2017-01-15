import de.dlkw.graphql.exp.types {
    GQLObjectType,
    GQLField,
    GQLNonNullType,
    gqlStringType,
    gqlBooleanType,
    GQLListType,
    ArgumentDefinition,
    GQLEnumType,
    GQLEnumValue,
    TypeKind,
    GQLTypeReference,
    resolveAllTypeReferences
}

object introspection
{
    GQLObjectType typeEnumValue = GQLObjectType {
        name_ = "__EnumValue";
        description = "An Enum value";
        fields_ = {
            GQLField {
                name = "name";
                type = GQLNonNullType(gqlStringType);
            },
            GQLField {
                name = "description";
                type = gqlStringType;
            },
            GQLField {
                name = "isDeprecated";
                type = GQLNonNullType(gqlBooleanType);
                Boolean resolver(Anything field, Anything ignored)
                {
                    assert (is GQLEnumValue field);
                    return field.deprecated;
                }
            },
            GQLField {
                name = "deprecationReason";
                type = gqlStringType;
            }
        };
    };

    GQLObjectType typeInputValue = GQLObjectType {
        name_ = "__InputValue";
        description = "An input value...";
        fields_ = {
            GQLField {
                name = "name";
                type = GQLNonNullType(gqlStringType);
            },
            GQLField {
                name = "description";
                type = gqlStringType;
            },
            GQLField {
                name = "type";
                type = GQLNonNullType(GQLTypeReference("__Type"));
            },
            GQLField {
                name = "defaultValue";
                type = gqlStringType;
            }
        };
    };

    GQLObjectType typeField = GQLObjectType {
        name_ = "__Field";
        description = "A field...";
        fields_ = {
            GQLField {
                name = "name";
                type = GQLNonNullType(gqlStringType);
            },
            GQLField {
                name = "description";
                type = gqlStringType;
            },
            GQLField {
                name = "args";
                type = GQLNonNullType(GQLListType(GQLNonNullType(typeInputValue)));
            },
            GQLField {
                name = "type";
                type = GQLNonNullType(GQLTypeReference("__Type"));
            },
            GQLField {
                name = "isDeprecated";
                type = GQLNonNullType(gqlBooleanType);
                Boolean resolver(Anything field, Anything ignored)
                {
                    assert (is GQLField<Anything> field);
                    return field.deprecated;
                }
            },
            GQLField {
                name = "deprecationReason";
                type = gqlStringType;
            }
        };
    };

    shared GQLObjectType typeType = GQLObjectType {
        name_ = "__Type";
        description = "A type...";
        fields_ = {
            GQLField {
                name = "kind";
                type = GQLNonNullType(GQLEnumType("__TypeKind", {
                    GQLEnumValue("SCALAR", TypeKind.scalar),
                    GQLEnumValue("OBJECT", TypeKind.\iobject),
                    GQLEnumValue("INTERFACE", TypeKind.\iinterface),
                    GQLEnumValue("UNION", TypeKind.union),
                    GQLEnumValue("ENUM", TypeKind.enum),
                    GQLEnumValue("INPUT_OBJECT", TypeKind.inputObject),
                    GQLEnumValue("LIST", TypeKind.list),
                    GQLEnumValue("NON_NULL", TypeKind.nonNull)
                }));
            },
            GQLField {
                name = "name";
                type = gqlStringType;
            },
            GQLField {
                name = "description";
                type = gqlStringType;
            },
            GQLField {
                name = "fields";
                type = GQLListType(GQLNonNullType(typeField));
                arguments = map({ "includeDeprecated"->ArgumentDefinition(gqlBooleanType, false) });
                {GQLField<Anything>*}? resolver(Anything objectType, Map<String, Anything> args)
                {
                    if (is GQLObjectType objectType) {
                        assert (is Boolean includeDeprecated = args["includeDeprecated"]);
                        if (includeDeprecated) {
                            return objectType.fields.items;
                        }
                        return objectType.fields.items.filter((field) => !field.deprecated);
                    }
                    return null;
                }
            },
            GQLField {
                name = "interfaces";
                type = GQLListType(GQLNonNullType(GQLTypeReference("__Type")));
            },
            GQLField {
                name = "possibleTypes";
                type = GQLListType(GQLNonNullType(GQLTypeReference("__Type")));
            },
            GQLField {
                name = "enumValues";
                type = GQLListType(GQLNonNullType(typeEnumValue));
                arguments = map({ "includeDeprecated"->ArgumentDefinition(gqlBooleanType, false) });
                {GQLEnumValue*}? resolver(Anything enumType, Map<String, Anything> args)
                {
                    if (is GQLEnumType enumType) {
                        assert (is Boolean includeDeprecated = args["includeDeprecated"]);
                        if (includeDeprecated) {
                            return enumType.enumValues;
                        }
                        return enumType.enumValues.filter((v) => !v.deprecated);
                    }
                    return null;
                }
            },
            GQLField {
                name = "inputValues";
                type = GQLListType(GQLNonNullType(typeInputValue));
            },
            GQLField {
                name = "ofType";
                type = GQLTypeReference("__Type");
            }
        };
    };

    GQLObjectType typeDirective = GQLObjectType {
        name_ = "__Directive";
        description = "A directive...";
        fields_ = {
            GQLField {
                name = "name";
                type = GQLNonNullType(gqlStringType);
            },
            GQLField {
                name = "description";
                type = gqlStringType;
            },
            GQLField {
                name = "locations";
                type = GQLNonNullType(GQLListType(GQLNonNullType(GQLEnumType("__DirectiveLocation", {
                    GQLEnumValue("QUERY"),
                    GQLEnumValue("MUTATION"),
                    GQLEnumValue("FIELD"),
                    GQLEnumValue("FRAGMENT_DEFINITION"),
                    GQLEnumValue("FRAGMENT_SPREAD"),
                    GQLEnumValue("INLINE_FRAGMENT")
                }))));
            },
            GQLField {
                name = "args";
                type = GQLNonNullType(GQLListType(GQLNonNullType(typeInputValue)));
            }
        };
    };

    shared GQLObjectType typeSchema = GQLObjectType {
        name_ = "__Schema";
        description = "The schema...";
        fields_ = {
            GQLField {
                name = "types";
                type = GQLNonNullType(GQLListType(GQLNonNullType(typeType)));
            },
            GQLField {
                name = "queryType";
                type = GQLNonNullType(typeType);
            },
            GQLField {
                name = "mutationType";
                type = typeType;
            },
            GQLField {
                name = "directives";
                type = GQLNonNullType(GQLListType(GQLNonNullType(typeDirective)));
            }
        };
    };

    resolveAllTypeReferences(typeSchema, map({ typeType.name->typeType }));
}