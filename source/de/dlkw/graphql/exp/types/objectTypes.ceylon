import ceylon.language.meta {
    type
}
import ceylon.collection {
    MutableSet,
    HashSet,
    SetMutator
}
import ceylon.logging {
    Logger,
    logger
}

Logger log = logger(`package`);

shared abstract class GQLAbstractObjectType(name, description)
    extends GQLNullableType(TypeKind.\iobject, name, description)
{
    String name;
    String? description;
    shared formal Map<String, GQLField<Anything>> fields;
}

shared class GQLObjectType(name_, {GQLField<Anything>+} fields_, shared {GQLInterfaceType*} interfaces={}, description=null)
    extends GQLAbstractObjectType(name_, description)
{
    String name_;
    String? description;

    shared actual String name => name_;

    shared actual Map<String, GQLField<Anything>> fields = map(fields_.map((field) => field.name -> field), duplicateDetector);

    value message = StringBuilder();
    for (iface in interfaces) {
        for (ifield in iface.fields.items) {
            value field = fields[ifield.name];
            if (is Null field) {
                message.appendNewline().append("object type ``name`` does not implement field ``ifield.name`` of interface ``iface.name``");
            }
            else if (!field.type.isSameTypeAs(ifield.type)) {
                message.appendNewline().append("field ``field.name`` of object type ``name`` has type ``field.type.wrappedName`` which does not match type ``ifield.type.wrappedName`` from implemented type ``iface.name``");
            }
        }
    }
    if (!message.empty) {
        throw AssertionError("not implementing interfaces:``message``");
    }
    shared actual Boolean isSameTypeAs(GQLType other) => this === other;

    shared actual String wrappedName => name_;

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

    // what to do here?
    shared actual Boolean isSameTypeAs(GQLType other) => nothing;
    shared actual String wrappedName => nothing;

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


shared interface GQLAbstractType of GQLInterfaceType | GQLUnionType
    satisfies Named
{
    shared formal actual String name;
}
shared class GQLInterfaceType(String name_, fields_, String? description=null)
extends GQLNullableType(TypeKind.\iinterface, name_, description)
    satisfies GQLAbstractType
{
    shared actual String name => name_;
    {GQLField<Anything>+} fields_;
    for (field in fields_) {
        if (exists r = field.resolver) {
            log.warn("field ``field.name`` of interface ``name_`` has a resolver defined, which will never be used");
        }
    }
    shared Map<String, GQLField<Anything>> fields = map(fields_.map((f) => f.name->f), duplicateDetector);
    shared actual Boolean isSameTypeAs(GQLType other) => this === other;

    shared actual String wrappedName => name_;
}

shared class GQLUnionType(String name_, shared {GQLObjectType+} types, String? description= null)
extends GQLNullableType(TypeKind.union, name_, description)
    satisfies GQLAbstractType
{
    isSameTypeAs(GQLType other) => this === other;
    wrappedName => name_;
    shared actual String name => name_;
}

shared interface TypeResolver
{
    shared formal GQLType resolveAbstractType(GQLAbstractType abstractType, Object objectValue);
}

GQLField<Anything> duplicateDetector(GQLField<Anything> earlier, GQLField<Anything> later) {
    if (!later === earlier) {
        throw AssertionError("duplicate field definition in type");
    }
    return earlier;
}
