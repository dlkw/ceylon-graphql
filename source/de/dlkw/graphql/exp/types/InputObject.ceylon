shared class GQLInputObjectType(String name, String? description, {GQLInputField+} fields)
    extends GQLNullableType(TypeKind.inputObject, name, description)
    satisfies InputCoercing<Map<String, Anything>>
{
    //shared Map<String, GQLInputField> ffields = map(fields.map((field)=>field.name->field));
    doCoerceInput = identity<Map<String, Anything>>;
}

shared class GQLInputField(name, type, description)
{
    shared String name;
    shared GQLScalarType<Object, Nothing> | GQLEnumType | GQLInputObjectType type;
    shared String? description;
}
