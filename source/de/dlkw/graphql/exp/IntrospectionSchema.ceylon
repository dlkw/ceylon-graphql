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
    resolveAllTypeReferences,
    GQLInputField,
    Undefined
}

object introspection
{
    GQLObjectType typeEnumValue = GQLObjectType {
        name = "__EnumValue";
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
                    assert (is GQLEnumValue<Anything> field);
                    return field.deprecated;
                }
            },
            GQLField {
                name = "deprecationReason";
                type = gqlStringType;
            }
        };
    };

    String? defaultValueToString(Anything defaultValue)
    {
        // FIXME need to do this depending on argumentDefinition.type, not value type
        if (is Undefined defaultValue) {
            return null;
        }
        else if (is Map<String, Anything> defaultValue) {
            return "{``",".join({for (n->v in defaultValue) "``n``:``defaultValueToString(v) else "null" ``"})``}";
        }
        else if (is String defaultValue) {
            return "\"``defaultValue``\"";
        }
        return defaultValue?.string;
    }

    GQLObjectType typeInputValue = GQLObjectType {
        name = "__InputValue";
        description = "An input value...";
        fields_ = {
            GQLField {
                name = "name";
                type = GQLNonNullType(gqlStringType);
                resolver = ((x, d){
                    assert (is <String->Anything> x);
                    return x.key;
                });
            },
            GQLField {
                name = "description";
                type = gqlStringType;
                resolver = ((x, d){
                    assert (is <String->Anything> x);
                    if (is ArgumentDefinition<Anything> item = x.item) {
                        return item.description;
                    }
                    else if (is GQLInputField item = x.item) {
                        return item.description;
                    }
                    throw;
                });
            },
            GQLField {
                name = "type";
                type = GQLNonNullType(GQLTypeReference("__Type"));
                resolver = ((x, d){
                    assert (is <String->Anything> x);
                    if (is ArgumentDefinition<Anything> item = x.item) {
                        return item.type;
                    }
                    else if (is GQLInputField item = x.item) {
                        return item.type;
                    }
                    throw;
                });
            },
            GQLField {
                name = "defaultValue";
                type = gqlStringType;
                resolver = ((x, d){
                    assert (is <String->Anything> x);
                    if (is ArgumentDefinition<Anything> item = x.item) {
                        return defaultValueToString(item.defaultValue);
                    }
                    return null;
                });
            }
        };
    };

    GQLObjectType typeField = GQLObjectType {
        name = "__Field";
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
                    assert (is GQLField field);
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
        name = "__Type";
        description = "A type...";
        fields_ = {
            GQLField {
                name = "kind";
                type = GQLNonNullType(GQLEnumType("__TypeKind", [
                    GQLEnumValue("SCALAR", TypeKind.scalar),
                    GQLEnumValue("OBJECT", TypeKind.\iobject),
                    GQLEnumValue("INTERFACE", TypeKind.\iinterface),
                    GQLEnumValue("UNION", TypeKind.union),
                    GQLEnumValue("ENUM", TypeKind.enum),
                    GQLEnumValue("INPUT_OBJECT", TypeKind.inputObject),
                    GQLEnumValue("LIST", TypeKind.list),
                    GQLEnumValue("NON_NULL", TypeKind.nonNull)
                ]));
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
                arguments = map({ "includeDeprecated"->ArgumentDefinition(gqlBooleanType, null, false) });
                {GQLField*}? resolver(Anything objectType, Map<String, Anything> args)
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
                arguments = map({ "includeDeprecated"->ArgumentDefinition(gqlBooleanType, null, false) });
                {GQLEnumValue<Anything>*}? resolver(Anything enumType, Map<String, Anything> args)
                {
                    if (is GQLEnumType<Anything> enumType) {
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
                name = "inputFields";
                type = GQLListType(GQLNonNullType(typeInputValue));
            },
            GQLField {
                name = "ofType";
                type = GQLTypeReference("__Type");
            }
        };
    };

    GQLObjectType typeDirective = GQLObjectType {
        name = "__Directive";
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
                type = GQLNonNullType<GQLListType<GQLNonNullType<GQLEnumType<DirectiveLocation>, String>, Null>, Null>(GQLListType(GQLNonNullType(GQLEnumType("__DirectiveLocation", [
                    GQLEnumValue("QUERY", DirectiveLocation.query),
                    GQLEnumValue("MUTATION", DirectiveLocation.mutation),
                    GQLEnumValue("FIELD", DirectiveLocation.field),
                    GQLEnumValue("FRAGMENT_DEFINITION", DirectiveLocation.fragmentDefinition),
                    GQLEnumValue("FRAGMENT_SPREAD", DirectiveLocation.fragmentSpread),
                    GQLEnumValue("INLINE_FRAGMENT", DirectiveLocation.inlineFragment)
                ]))));
            },
            GQLField {
                name = "args";
                type = GQLNonNullType(GQLListType(GQLNonNullType(typeInputValue)));
            }
        };
    };

    shared GQLObjectType typeSchema = GQLObjectType {
        name = "__Schema";
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
