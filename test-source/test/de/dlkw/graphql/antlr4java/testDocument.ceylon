import ceylon.test {
    test,
    assertEquals,
    assertNull,
    assertTrue,
    assertFalse,
    fail
}

import de.dlkw.graphql.antlr4java {
    parseDocument,
    ParseError
}
import de.dlkw.graphql.exp {
    OperationType,
    AField,
    FragmentDefinition,
    FragmentSpread,
    InlineFragment,
    Var,
    Schema
}
import de.dlkw.graphql.exp.types {
    gqlIntType,
    gqlStringType,
    Undefined,
    GQLField,
    GQLObjectType,
    ArgumentDefinition,
    GQLEnumType,
    GQLEnumValue,
    GQLInputObjectType,
    GQLInputField
}

Schema simplestSchema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType)}), null);

test
shared void testAnonymousQuery()
{
    String doc = "{ f }";
    value parsedDoc = parseDocument(doc, simplestSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (exists op = parsedDoc.operationDefinition(null));
    assertNull(op.name);
    assertEquals(op.type, OperationType.query);
}

test
shared void testNamedQuery()
{
    String doc = "query q { f }";
    value parsedDoc = parseDocument(doc, simplestSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (exists op = parsedDoc.operationDefinition(null));
    assert (exists name = op.name);
    assertEquals(name, "q");
    assertEquals(op.type, OperationType.query);
}

test
shared void testNamedQueryByName()
{
    String doc = "query q { f }";
    value parsedDoc = parseDocument(doc, simplestSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (exists op = parsedDoc.operationDefinition("q"));
    assert (exists name = op.name);
    assertEquals(name, "q");
    assertEquals(op.type, OperationType.query);
}

test
shared void testAnonymousQueryWithKeyword()
{
    String doc = "query { f }";
    value parsedDoc = parseDocument(doc, simplestSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (exists op = parsedDoc.operationDefinition(null));
    assert (is Null name = op.name);
    assertEquals(op.type, OperationType.query);
}

test
shared void testNamedMutation()
{
    String doc = "mutation q { f }";
    value parsedDoc = parseDocument(doc, simplestSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (exists op = parsedDoc.operationDefinition(null));
    assert (exists name = op.name);
    assertEquals(name, "q");
    assertEquals(op.type, OperationType.mutation);
}

test
shared void testFieldNoAlias()
{
    String doc = "{ f }";
    value parsedDoc = parseDocument(doc, simplestSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (exists op = parsedDoc.operationDefinition(null));
    assert (is AField f = op.selectionSet.first);
    assertEquals(f.name, "f");
    assertNull(f.alias_);
    assertNull(f.selectionSet);
}

test
shared void testFieldWithAlias()
{
    String doc = "{ a:f }";
    value parsedDoc = parseDocument(doc, simplestSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (exists op = parsedDoc.operationDefinition(null));
    assert (is AField f = op.selectionSet.first);
    assertEquals(f.name, "f");
    assertEquals(f.alias_, "a");
    assertNull(f.selectionSet);
}

test
shared void testFieldWithSubfield()
{
    String doc = "{a:f{s}}";
    value parsedDoc = parseDocument(doc, simplestSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is AField f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assert (exists selSet = f.selectionSet);
    assert (is AField s = selSet.first);
    assertEquals(s.name, "s");
}

test
shared void testFieldWithStringArgumentNamedNull()
{
    String doc = "{f(null:\"o8\")}";
    value parsedDoc = parseDocument(doc, simplestSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is AField f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is String a = f.arguments["null"]);
    assertEquals(a, "o8");
}

test
shared void testFieldWithNullArgument()
{
    String doc = "{f(a:null)}";
    value parsedDoc = parseDocument(doc, simplestSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is AField f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is Null a = f.arguments.get("a"));
    assertNull(a);
}

test
shared void testFieldWithTrueArgument()
{
    String doc = "{f(a:true)}";
    value parsedDoc = parseDocument(doc, simplestSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is AField f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is Boolean a = f.arguments["a"]);
    assertEquals(a, true);
}

test
shared void testFieldWithFalseArgument()
{
    String doc = "{f(a:false)}";
    value parsedDoc = parseDocument(doc, simplestSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is AField f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is Boolean a = f.arguments["a"]);
    assertEquals(a, false);
}

test
shared void testFieldWithEnumArgument()
{
    String doc = "{f(true:boing)}";
    value parsedDoc = parseDocument(doc, simplestSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is AField f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is String a = f.arguments["true"]);
    assertEquals(a, "boing");
}

test
shared void testFieldWithIntArgument()
{
    String doc = "{f(true:5)}";
    value parsedDoc = parseDocument(doc, simplestSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is AField f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is Integer a = f.arguments["true"]);
    assertEquals(a, 5);
}

test
shared void testFieldWithFloatArgument()
{
    String doc = "{f(true:5.1)}";
    value parsedDoc = parseDocument(doc, simplestSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is AField f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is Float a = f.arguments["true"]);
    assertEquals(a, 5.1);
}

test
shared void testFieldWithListArgument()
{
    String doc = "{f(true:[3, $vv, \"4\"])}";
    value parsedDoc = parseDocument(doc, simplestSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is AField f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is Sequence<Var|Anything> a = f.arguments["true"]);
    assertEquals(a.size, 3);
    assert (is Integer e0 = a[0]);
    assertEquals(e0, 3);
    assert (is Var e1 = a[1]);
    assertEquals(e1.name, "vv");
    assert (is String e2 = a[2]);
    assertEquals(e2, "4");
}

test
shared void testFieldWithObjectArgument()
{
    String doc = "{f(true:{s:\"v\", ff:$vvv})}";
    value parsedDoc = parseDocument(doc, simplestSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is AField f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is Map<> a = f.arguments["true"]);
    assertEquals(a.size, 2);
    value s = a.get("s");
    assert (is String s);
    assertEquals(s, "v");
    value ff = a.get("ff");
    assert (is Var ff);
    assertEquals(ff.name, "vvv");
}

test
shared void testFragmentDefinition()
{
    String doc = "fragment fr on t { f1 }";
    value parsedDoc = parseDocument(doc, simplestSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is FragmentDefinition fr = parsedDoc.fragmentDefinition("fr"));
    assertEquals(fr.name, "fr");
    assertEquals(fr.typeCondition, "t");
    value sel = fr.selectionSet.first;
    assert (is AField sel);
    assertEquals(sel.name, "f1");
}

test
shared void testFragmentSpread()
{
    String doc = "{ ... fs }";
    value parsedDoc = parseDocument(doc, simplestSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is FragmentSpread fs = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(fs.name, "fs");
}

test
shared void testInlineFragment()
{
    String doc = "{ ... {sf1}}";
    value parsedDoc = parseDocument(doc, simplestSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is InlineFragment inl = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertNull(inl.typeCondition);
    assert (is AField sf1 = inl.selectionSet.first);
    assertEquals(sf1.name, "sf1");
}

test
shared void testIntVariableWithDefaultValue()
{
    Schema varSchema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType, null, map({"a"->ArgumentDefinition(gqlIntType)}))}), null);
    String doc = "query ($v1:Int=4){f(a:$v)}";
    value parsedDoc = parseDocument(doc, varSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (exists vd = parsedDoc.operationDefinition(null)?.variableDefinitions);
    assertEquals(vd.size, 1);
    assert (exists varDef = vd.get("v1"));
    assertEquals(varDef.type, gqlIntType);
    assertEquals(varDef.defaultValue, 4);
}

test
shared void testIntVariableWithoutDefaultValue()
{
    Schema varSchema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType, null, map({"a"->ArgumentDefinition(gqlIntType)}))}), null);
    String doc = "query ($v1:Int){f(a:$v)}";
    value parsedDoc = parseDocument(doc, varSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (exists vd = parsedDoc.operationDefinition(null)?.variableDefinitions);
    assertEquals(vd.size, 1);
    assert (exists varDef = vd.get("v1"));
    assertEquals(varDef.type, gqlIntType);
    assert (is Undefined default_ = varDef.defaultValue);
}

test
shared void testIntVariableWithNullDefaultValue()
{
    Schema varSchema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType, null, map({"a"->ArgumentDefinition(gqlIntType)}))}), null);
    String doc = "query ($v1:Int=null){f(a:$v)}";
    value parsedDoc = parseDocument(doc, varSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (exists vd = parsedDoc.operationDefinition(null)?.variableDefinitions);
    assertEquals(vd.size, 1);
    assert (exists varDef = vd.get("v1"));
    assertEquals(varDef.type, gqlIntType);
    assert (is Null default_ = varDef.defaultValue);
}

test
shared void testStringVariable()
{
    String doc = "query ($v1:String=\"k\"){f(a:$v)}";
    value parsedDoc = parseDocument(doc, simplestSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (exists vd = parsedDoc.operationDefinition(null)?.variableDefinitions);
    assertEquals(vd.size, 1);
    assert (exists varDef = vd.get("v1"));
    assertEquals(varDef.type, gqlStringType);
    assertEquals(varDef.defaultValue, "k");
}

test
shared void testStringEnumVariableWithIllegalDefaultValue()
{
    value enumType = GQLEnumType("Testenum", [GQLEnumValue<>("k")]);
    Schema varSchema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType, null, map({"e"->ArgumentDefinition(enumType)}))}), null);
    String doc = "query ($v1:Testenum=popop){f(a:$v)}";
    try {
        value parsedDoc = parseDocument(doc, varSchema);
        if (is ParseError parsedDoc) {
            print(parsedDoc.errorInfos);
            throw ;
        }
        fail("exception expected");
    }
    catch (AssertionError e) {
        assert (e.message.startsWith("illegal default value <popop>"));
    }
}

test
shared void testStringEnumVariable()
{
    value enumType = GQLEnumType("Testenum", [GQLEnumValue<>("k")]);
    Schema varSchema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType, null, map({"e"->ArgumentDefinition(enumType)}))}), null);
    String doc = "query ($v1:Testenum=k){f(a:$v)}";
    value parsedDoc = parseDocument(doc, varSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (exists vd = parsedDoc.operationDefinition(null)?.variableDefinitions);
    assertEquals(vd.size, 1);
    assert (exists varDef = vd.get("v1"));
    assertEquals(varDef.type, enumType);
    assertEquals(varDef.defaultValue, "k");
}

class E of kk|kl
{
    shared new kk{}
    shared new kl{}
}

test
shared void testEnumEnumVariable()
{
    value enumType = GQLEnumType<E>("Testenum", [GQLEnumValue("k", E.kk), GQLEnumValue("l", E.kl)]);
    Schema varSchema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType, null, map({"e"->ArgumentDefinition(enumType)}))}), null);
    String doc = "query ($v1:Testenum=k){f(e:$v1)}";
    value parsedDoc = parseDocument(doc, varSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (exists vd = parsedDoc.operationDefinition(null)?.variableDefinitions);
    assertEquals(vd.size, 1);
    assert (exists varDef = vd.get("v1"));
    assertEquals(varDef.type, enumType);
    assertEquals(varDef.defaultValue, E.kk);
}

test
shared void testObjectVariable()
{
    value enumType = GQLEnumType<E>("Testenum", [GQLEnumValue("k", E.kk), GQLEnumValue("l", E.kl)]);
    value inObjType = GQLInputObjectType("TestInObj", [GQLInputField("k", gqlStringType), GQLInputField("l", enumType)]);
    Schema varSchema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType, null, map({"e"->ArgumentDefinition(enumType)}))}), null);
    String doc = "query ($v1:Testenum=k){f(e:$v1)}";
    value parsedDoc = parseDocument(doc, varSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (exists vd = parsedDoc.operationDefinition(null)?.variableDefinitions);
    assertEquals(vd.size, 1);
    assert (exists varDef = vd.get("v1"));
    assertEquals(varDef.type, enumType);
    assertEquals(varDef.defaultValue, E.kk);
}
