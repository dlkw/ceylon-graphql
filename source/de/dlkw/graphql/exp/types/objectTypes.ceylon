import ceylon.language.meta {
    type
}
import ceylon.collection {
    MutableSet,
    HashSet,
    SetMutator
}
shared abstract class GQLAbstractObjectType(name, description)
    extends GQLNullableType(TypeKind.\iobject, name, description)
{
    String name;
    String? description;
    shared formal Map<String, GQLField<Anything>> fields;
}

shared class GQLObjectType(name_, {GQLField<Anything>+} fields_, description=null)
    extends GQLAbstractObjectType(name_, description)
{
    String name_;
    String? description;

    shared actual String name => name_;

    shared actual Map<String, GQLField<Anything>> fields = map(fields_.map((field) => field.name -> field));
}

shared class GQLField<out Value>(name, type, description=null, arguments=emptyMap, deprecated=false, deprecationReason=null, resolver=null)
{
    shared String name;
    shared GQLType type;
    shared String? description;
    shared Boolean deprecated;
    shared String? deprecationReason;
    shared Map<String, ArgumentDefinition<Object>> arguments;
    "Optional resolver for a field in an object. First parameter is the object value of the object
     containing the field to resolve, second the field's argument values"
    shared Anything(Anything, Map<String, Anything>)? resolver;

    assertGQLName(name);

    "Alias for [[arguments]] to provide the key/value pair in the GraphQL introspection type."
    shared Map<String, ArgumentDefinition<Object>> args => arguments;
}

shared class ArgumentDefinition<out Value>(type, defaultValue=undefined)
    given Value satisfies Object
{
    shared <GQLType & InputCoercing<Value, Nothing>> type;

    "The default value used if no value is specified in the graphQL document.
     May be null if null is the default value. If no default value is intended,
     use value undefined."
    shared Value? | Undefined defaultValue;
}

shared abstract class Undefined() of undefined {}
shared object undefined extends Undefined() {}

shared class GQLTypeReference(String name_)
        extends GQLAbstractObjectType(name_, null)
{
    shared actual String name => name_;

    variable GQLObjectType? holder = null;

    shared GQLObjectType referenced
    {
        if (exists ref = holder) {
            return ref;
        }
        throw AssertionError("reference ``name`` not resolved yet");
    }

    assign referenced
    {
        if (exists x=holder) {
            throw AssertionError("already resolved reference ``name``");
        }
        holder = referenced;
    }

    description => referenced.description;

    shared actual Map<String,GQLField<Anything>> fields => referenced.fields;
}

void resolveTypeReference(GQLTypeReference typeReference, Map<String, GQLObjectType> referenceableTypes)
{
    GQLObjectType? referenced = referenceableTypes[typeReference.name];

    if (exists referenced) {
        typeReference.referenced = referenced;
    }
    else {
        throw AssertionError("No type found for reference ``typeReference.name``, maybe referenced type is not an object type.");//TODO
    }
}

void recurseToResolveTypeReference(type, referenceableTypes, startedResolvingTypes)
{
    GQLType type;
    Map<String, GQLObjectType> referenceableTypes;
    SetMutator<GQLObjectType> startedResolvingTypes;

    switch (type)
    case (is GQLListType<GQLType> | GQLNonNullType<GQLType>) {
        value inner = type.inner;
        recurseToResolveTypeReference(inner, referenceableTypes, startedResolvingTypes);
    }
    case (is GQLTypeReference) {
        resolveTypeReference(type, referenceableTypes);
    }
    case (is GQLObjectType) {
        if (startedResolvingTypes.add(type)) {
            for (fieldType in type.fields.items.map((field) => field.type)) {
                recurseToResolveTypeReference(fieldType, referenceableTypes, startedResolvingTypes);
            }
        }
    }
    else {
        // do nothing
    }
}

shared void resolveAllTypeReferences(GQLObjectType type, Map<String, GQLObjectType> referenceableTypes)
{
    MutableSet<GQLObjectType> startedResolvingTypes = HashSet<GQLObjectType>();
    recurseToResolveTypeReference(type, referenceableTypes, startedResolvingTypes);
}

