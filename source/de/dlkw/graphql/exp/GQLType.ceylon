/*
class GQLInterfaceType<Value>({GQLField+} fields)
    extends GQLNullableType<Value>()
{
    shared Map<String, GQLField> ffields = map(fields.map((field)=>field.name->field));
    shared actual Value coerceOutputValue(Anything value_) => nothing;

}

class GQLUnionType<Value>({GQLObjectType+} types)
    extends GQLNullableType<Value>()
{
    shared actual Value coerceOutputValue(Anything value_) => nothing;


}
*/

/*
class GQLInputField(name, type, description)
{
    shared String name;
    shared GQLScalarType<Anything> | GQLEnumType | GQLInputObjectType type;
    shared String? description;
}

class GQLInputObjectType({GQLInputField+} fields)
{
    shared Map<String, GQLInputField> ffields = map(fields.map((field)=>field.name->field));
}
*/

shared class GQLError(){}
shared class QueryError()
    extends GQLError()
{}
