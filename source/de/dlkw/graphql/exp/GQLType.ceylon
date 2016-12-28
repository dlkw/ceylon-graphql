shared interface GQLType<out Value>
    given Value satisfies Result
{
    "Coerces a result value obtained from field resolution to the corresponding GQLValue value
     according to the GraphQL result coercion rules."
    shared formal Value coerceResult(Anything result);

    "Coerces an input value (variable or argument value) to the corresponding GQLValue value
     according to the GraphQL input coercion rules."
    shared formal Value | CoercionError coerceInput(Anything input);
}

shared abstract class GQLNullableType<out Value>()
    satisfies GQLType<Value>
    given Value satisfies Result
{
}

shared class GQLNonNullType<out Inner, out Value>(inner)
    satisfies GQLType<Value>
    given Inner satisfies GQLNullableType<Value>
    given Value satisfies Result
{
    shared Inner inner;

    shared actual Value coerceResult(Anything result)
        => inner.coerceResult(result);

    shared actual Value coerceInput(Anything input) => nothing;
}

shared class GQLListType<out Inner, out Value>(inner)
    extends GQLNullableType<GQLListValue<Value>>()
    given Inner satisfies GQLType<Value>
    given Value satisfies Result
{
    shared Inner inner;

    shared actual GQLListValue<Value> coerceResult(Anything value_)
    {
        return nothing;
    }

    shared actual GQLListValue<Value> coerceInput(Anything input) => nothing;
}

shared abstract class GQLScalarType<out Value>()
    extends GQLNullableType<Value>()
    given Value satisfies Result
{
}

void assertGQLName(String name)
{
    assert (exists first = name.first);
    assert (first in 'a'..'z' || first in 'A' ..'Z' || first == '_');
    for (c in name[1...]) {
        assert (c in 'a'..'z' || c in 'A' ..'Z' || c in '0'.. '9'|| c == '_');
    }
}

shared class GQLEnumValue(name, value__ =null, description=null, deprecated=false, deprecationReason=null)
{
    shared String name;
    assertGQLName(name);
    assert (name != "true" && name != "false" && name != "null");

    String? value__;
    //value tmp = if (exists value__) then value__ else if (is Value name) then name else null;
    value tmp = if (exists value__) then value__ else name;
    shared String value_ = tmp;

    shared String? description;
    shared Boolean deprecated;
    shared String? deprecationReason;
    if (!deprecated) {
        assert (is Null deprecationReason);
    }
}

shared class GQLEnumType({GQLEnumValue+} values)
    extends GQLScalarType<GQLStringValue>()
{
    shared actual GQLStringValue coerceResult(Anything value_)
    {
        if (is String value_) {
            return GQLStringValue(value_);
        }
        throw AssertionError("not a String: ``value_?.string else "null"``");
    }

    shared actual GQLStringValue coerceInput(Anything input) => nothing;
}

shared class GQLObjectType(name, {GQLField<Result>+} fields_, description=null)
    extends GQLNullableType<GQLObjectValue>()
{
    shared String name;
    shared String? description;

    shared Map<String, GQLField<Result>> fields = map(fields_.map((field) => field.name -> field));

    shared actual GQLObjectValue coerceResult(Anything value_)
    {
        return nothing;
    }

    shared actual GQLObjectValue coerceInput(Anything input) => nothing;
}

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

shared class GQLIntType()
    extends GQLScalarType<GQLIntValue>()
{
    shared actual GQLIntValue coerceResult(Anything value_)
    {
        if (is Integer value_) {
            if (value_ >= 2 ^ 31) {
                throw AssertionError("could not coerce positive Integer to 32 bit");
            }
            if (value_ < -(2 ^ 31)) {
                throw AssertionError("could not coerce negative Integer to 32 bit");
            }
            return GQLIntValue(value_);
        }
        throw AssertionError("not an Integer: ``value_?.string else "null"``");
    }

    shared actual GQLIntValue coerceInput(Anything input) => nothing;
}

/*
class GQLFloatType()
        extends GQLScalarType<Float>()
{
    shared actual Float coerceResult(Anything value_) => nothing;

}
*/

class GQLStringType()
        extends GQLScalarType<GQLStringValue>()
{
    shared actual GQLStringValue coerceResult(Anything value_) => nothing;

    shared actual GQLStringValue coerceInput(Anything input) => nothing;
}

/*
class GQLBooleanType()
        extends GQLScalarType<Boolean>()
{
    shared actual Boolean coerceResult(Anything value_) => nothing;

}

class GQLIDType()
        extends GQLScalarType<String>()
{
    shared actual String coerceResult(Anything value_) => nothing;

}
*/

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

shared class GQLField<out Value>(name, type, description=null, arguments=emptyMap, deprecated=false, resolver=null)
{
    shared String name;
    shared GQLType<Value> type;
    shared String? description;
    shared Boolean deprecated;
    shared Map<String, ArgumentDefinition<Result>> arguments;
    shared Anything(Anything, Map<String, Result?>)? resolver;

    assertGQLName(name);
}

shared class ArgumentDefinition<out Value>(type, defaultValue=undefined)
    given Value satisfies Result
{
    shared GQLType<Value> type;
    "The default value used if no value is specified in the graphQL document.
     May be null if null is the default value. If no default value is intended,
     use value undefined."
    shared Value?|Undefined defaultValue;
}

shared class GQLError(){}
shared class QueryError()
    extends GQLError()
{}
shared class CoercionError()
    extends QueryError()
{}

/*
shared void run()
{
    value queryRoot = GQLObjectType<Anything>("n", {
        GQLField{
                "fA";
                GQLIntType();
                "descA";
        },
        GQLField{
                name="fB";
                type=GQLNonNullType(GQLIntType());
                description="descB";
        },
        GQLField("nicks", GQLListType(GQLIntType()), "descNicks")/*,
        GQLField{
                name="enum";
                type=GQLEnumType{
                        GQLEnumValue{"V1";5;"descr";true;"Deprecation Reason";},
                        GQLEnumValue("V2")
                };
                description="descrEnum";
        }*/
    });

    value schema = Schema(queryRoot, null);
    value doc = doci();

    print(schema.execute(doc));
}
*/