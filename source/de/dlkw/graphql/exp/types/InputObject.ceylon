shared class GQLInputObjectType(String name, {GQLInputField<>+} fields, String? description = null)
    extends GQLNullableType<String>(TypeKind.inputObject, name, description)
    satisfies InputCoercing<String, Map<String, Anything>>
{
    //shared Map<String, GQLInputField> ffields = map(fields.map((field)=>field.name->field));
    doCoerceInput = identity<Map<String, Anything>>;
    shared actual Boolean isSameTypeAs(GQLType<Anything> other) => this === other;

    shared actual String wrappedName => name;
}

shared class GQLInputField<Enum=Nothing>(name, type, description = null)
    given Enum satisfies Object
{
    shared String name;
    shared GQLScalarType<Object, Nothing> | GQLEnumType<Enum> | GQLInputObjectType type;
    shared String? description;
}
