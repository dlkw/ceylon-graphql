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
    extends GQLNullableType<String>(TypeKind.\iobject, name, description)
{
    String name;
    String? description;
    shared formal GQLObjectType type;
    shared formal Map<String, GQLField> fields;
    shared formal {GQLInterfaceType*} interfaces;
}

shared class GQLObjectType(name, {GQLField+} fields_, shared actual {GQLInterfaceType*} interfaces={}, description=null)
    extends GQLAbstractObjectType(name, description)
{
    String name;
    String? description;

    shared actual Map<String, GQLField> fields = map(fields_.map((field) => field.name -> field), duplicateDetector<GQLField>);

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
    shared actual GQLObjectType type => this;
    shared actual Boolean isSameTypeAs(GQLType<Anything> other) => this === other;

    shared actual String wrappedName => name;
}

shared class GQLField(name, type, description=null, arguments=emptyMap, deprecated=false, deprecationReason=null, resolver=null)
{
    shared String name;
    shared GQLType<String?> type;
    shared String? description;
    shared Boolean deprecated;
    shared String? deprecationReason;
    shared Map<String, ArgumentDefinition<Object>> arguments;
    "Optional resolver for a field in an object. First parameter is the object value of the object
     containing the field to resolve, second the field's argument values"
    shared Object?(Anything, Map<String, Object?>)? resolver;

    assertGQLName(name);

    "Alias for [[arguments]] to provide the key/value pair in the GraphQL introspection type."
    shared Map<String, ArgumentDefinition<Object>> args => arguments;
}

shared class ArgumentDefinition<out Value>(type, defaultValue=undefined)
    given Value satisfies Object
{
    shared GQLType<String?> & InputCoercingBase<String?, Value> type;

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

    shared actual Map<String,GQLField> fields => referenced.fields;
    shared actual {GQLInterfaceType*} interfaces=>referenced.interfaces;

    shared actual GQLObjectType type => referenced;

    shared actual Boolean isSameTypeAs(GQLType<Anything> other) => other === referenced;
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
    GQLType<Anything> type;
    Map<String, GQLObjectType> referenceableTypes;
    SetMutator<GQLObjectType> startedResolvingTypes;

    switch (type)
    case (is GQLNonNullType<GQLType<Anything>, Anything> | GQLListType<GQLType<Anything>, Anything>) {
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


shared abstract class GQLAbstractType(TypeKind kind, String name, String? description) of GQLInterfaceType | GQLUnionType
    extends GQLNullableType<String>(kind, name, description)
{
}
shared class GQLInterfaceType(String name, fields_, String? description=null)
extends GQLAbstractType(TypeKind.\iinterface, name, description)
{
    {GQLField+} fields_;
    for (field in fields_) {
        if (exists r = field.resolver) {
            log.warn("field ``field.name`` of interface ``name`` has a resolver defined, which will never be used");
        }
    }
    shared Map<String, GQLField> fields = map(fields_.map((f) => f.name->f), duplicateDetector<GQLField>);
    shared actual Boolean isSameTypeAs(GQLType<Anything> other) => this === other;

    shared actual String wrappedName => name;
}

shared class GQLUnionType(String name, shared {GQLObjectType+} types, String? description= null)
extends GQLAbstractType(TypeKind.union, name, description)
{
    isSameTypeAs(GQLType<Anything> other) => this === other;
    wrappedName => name;
}

shared interface TypeResolver
{
    shared formal GQLObjectType? resolveAbstractType(GQLAbstractType abstractType, Object objectValue);
}

Field duplicateDetector<Field>(Field earlier, Field later)
    given Field of GQLField | GQLInputField
{
    if (!(later of Identifiable) === (earlier of Identifiable)) {
        throw AssertionError("duplicate field definition in type");
    }
    return earlier;
}
