import ceylon.language.meta {
    type
}

import de.dlkw.graphql.exp {
    Var
}
shared class GQLInputObjectType(String name, {GQLInputField+} fields_, String? description = null)
    extends GQLNullableType<String>(TypeKind.inputObject, name, description)
    satisfies InputCoercingBase<String, Map<String, Anything>>
{
    Map<String, GQLInputField> fields = map(fields_.map((field) => field.name -> field), duplicateDetector<GQLInputField>);

    shared actual Map<String, Anything>? | Var | CoercionError coerceInput(Anything input)
    {
        if (is Null | Var input) {
            return input;
        }

        if (is Map<String, Anything> input) {
            class FieldCoercionException(shared String fieldName, shared CoercionError e) extends Exception(){}
            try {
                return map(input.map((fieldName -> fieldValue)
                {
                    value fieldDefinition = fields[fieldName];
                    if (is Null fieldDefinition) {
                        throw FieldCoercionException(fieldName, CoercionError("field does not exist"));
                    }
                    value elCoerced = fieldDefinition.type.coerceInput(fieldValue);
                    if (is CoercionError elCoerced) {
                        throw FieldCoercionException(fieldName, elCoerced);
                    }
                    return fieldName -> elCoerced;
                }));
            }
            catch (FieldCoercionException e) {
                return CoercionError("value of field ``e.fieldName`` could not be coerced: ``e.e.message``");
            }
        }

        return CoercionError("Cannot input-coerce input value ``input`` of type ``type(input)`` to `` `Map<String, Anything>` `` as ``name``: only possible for input type FIXME."); // FIXME
    }

    shared actual Boolean isSameTypeAs(GQLType<Anything> other) => this === other;

    shared actual String wrappedName => name;
}

shared class GQLInputField(name, type, description = null)
{
    shared String name;
    shared GQLScalarType<Object, Nothing> | GQLEnumType<Object> | GQLInputObjectType type;
    shared String? description;
}
