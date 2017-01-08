import ceylon.language.meta {
    type
}
import ceylon.collection {
    MutableSet,
    HashSet,
    SetMutator
}
shared abstract class GQLAbstractObjectType(name, description)
    extends GQLNullableType<String>(TypeKind.\iobject, name, description)
{
    String name;
    String? description;
    shared formal Map<String, GQLField<Anything, String?>> fields;
}

shared class GQLObjectType(name, {GQLField<Anything, String?>+} fields_, description=null)
    extends GQLAbstractObjectType(name, description)
{
    String name;
    String? description;

    shared actual Map<String, GQLField<Anything, String?>> fields = map(fields_.map((field) => field.name -> field));
}

shared class GQLField<out Value, out TypeName>(name, type, description=null, arguments=emptyMap, deprecated=false, resolver=null)
    given TypeName of String | Null
{
    shared String name;
    shared GQLType<TypeName> type;
    shared String? description;
    shared Boolean deprecated;
    shared Map<String, ArgumentDefinition<Object, String?>> arguments;
    "Optional resolver for a field in an object. First parameter is the object value of the object
     containing the field to resolve, second the field's argument values"
    shared Anything(Anything, Map<String, Anything>)? resolver;

    assertGQLName(name);

    "Alias for [[arguments]] to provide the key/value pair in the GraphQL introspection type."
    shared Map<String, ArgumentDefinition<Object, String?>> args => arguments;

    "Alias for [[deprecated]] to provide the key/value pair in the GraphQL introspection type."
    shared Boolean isDeprecated => deprecated;
}

shared class ArgumentDefinition<out Value, out TypeName>(type, defaultValue=undefined)
    given Value satisfies Object
    given TypeName of String | Null
{
    shared GQLType<TypeName> & InputCoercing<Value, Nothing> type;

    "The default value used if no value is specified in the graphQL document.
     May be null if null is the default value. If no default value is intended,
     use value undefined."
    shared Value? | Undefined defaultValue;
}

shared abstract class Undefined() of undefined {}
shared object undefined extends Undefined() {}

shared class GQLTypeReference(String name)
        extends GQLAbstractObjectType(name, null)
{
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

    shared actual Map<String,GQLField<Anything, String?>> fields => referenced.fields;
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
    GQLType<> type;
    Map<String, GQLObjectType> referenceableTypes;
    SetMutator<GQLObjectType> startedResolvingTypes;

    switch (type)
    case (is GQLListType<GQLType<>> | GQLNonNullType<GQLType<>>) {
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

