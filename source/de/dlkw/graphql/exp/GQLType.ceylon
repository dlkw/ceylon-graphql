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

shared class GQLError(){}
shared class QueryError()
    extends GQLError()
{}
