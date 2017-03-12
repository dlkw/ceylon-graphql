import ceylon.test {
    test,
    assertEquals,
    assertNull,
    fail
}

import de.dlkw.graphql.antlr4java {
    parseDocument,
    ParseError
}
import de.dlkw.graphql.exp {
    OperationType,
    Field,
    FragmentDefinition,
    FragmentSpread,
    InlineFragment,
    Var,
    Schema,
    EnumLiteral,
    IList
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
    GQLInputField,
    gqlFloatType,
    gqlBooleanType,
    GQLInputListType
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
    Schema schema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType)}), GQLObjectType("m", {GQLField("f", gqlStringType)}));
    String doc = "mutation q { f }";
    value parsedDoc = parseDocument(doc, schema);
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
    assert (is Field f = op.selectionSet.first);
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
    assert (is Field f = op.selectionSet.first);
    assertEquals(f.name, "f");
    assertEquals(f.alias_, "a");
    assertNull(f.selectionSet);
}

test
shared void testFieldWithSubfield()
{
    Schema schema = Schema(GQLObjectType("q", {GQLField("f", GQLObjectType("qq", {GQLField("s", gqlStringType)}))}), null);
    String doc = "{a:f{s}}";
    value parsedDoc = parseDocument(doc, schema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is Field f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assert (exists selSet = f.selectionSet);
    assert (is Field s = selSet.first);
    assertEquals(s.name, "s");
}

test
shared void testFieldWithStringArgumentNamedNull()
{
    Schema schema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType, null, map{"null"->ArgumentDefinition(gqlStringType)})}), null);
    String doc = "{f(null:\"o8\")}";
    value parsedDoc = parseDocument(doc, schema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is Field f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is String a = f.arguments["null"]);
    assertEquals(a, "o8");
}

test
shared void testFieldWithNullArgument()
{
    Schema schema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType, null, map{"a"->ArgumentDefinition(gqlBooleanType)})}), null);
    String doc = "{f(a:null)}";
    value parsedDoc = parseDocument(doc, schema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is Field f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is Null a = f.arguments.get("a"));
    assertNull(a);
}

test
shared void testFieldWithTrueArgument()
{
    Schema schema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType, null, map{"a"->ArgumentDefinition(gqlBooleanType)})}), null);
    String doc = "{f(a:true)}";
    value parsedDoc = parseDocument(doc, schema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is Field f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is Boolean a = f.arguments["a"]);
    assertEquals(a, true);
}

test
shared void testFieldWithFalseArgument()
{
    Schema schema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType, null, map{"a"->ArgumentDefinition(gqlBooleanType)})}), null);
    String doc = "{f(a:false)}";
    value parsedDoc = parseDocument(doc, schema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is Field f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is Boolean a = f.arguments["a"]);
    assertEquals(a, false);
}

test
shared void testFieldWithEnumArgument()
{
    value enumType = GQLEnumType("Testenum", [GQLEnumValue<>("boing")]);
    Schema schema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType, null, map{"true"->ArgumentDefinition(enumType)})}), null);
    String doc = "{f(true:boing)}";
    value parsedDoc = parseDocument(doc, schema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is Field f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is EnumLiteral a = f.arguments["true"]);
    assertEquals(a.value_, "boing");
}

test
shared void testFieldWithIntArgument()
{
    Schema schema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType, null, map{"true"->ArgumentDefinition(gqlIntType)})}), null);
    String doc = "{f(true:5)}";
    value parsedDoc = parseDocument(doc, schema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is Field f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is Integer a = f.arguments["true"]);
    assertEquals(a, 5);
}

test
shared void testFieldWithFloatArgument()
{
    Schema schema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType, null, map{"true"->ArgumentDefinition(gqlFloatType)})}), null);
    String doc = "{f(true:5.1)}";
    value parsedDoc = parseDocument(doc, schema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is Field f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is Float a = f.arguments["true"]);
    assertEquals(a, 5.1);
}

test
shared void testFieldWithIntListArgument()
{
    value argDef = ArgumentDefinition(GQLInputListType(gqlIntType));
    Schema schema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType, null, map{"true"->argDef})}), null);
    String doc = "{f(true:[3, $vv, 4])}";
    value parsedDoc = parseDocument(doc, schema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is Field f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is IList<Var|Anything> a = f.arguments["true"]);
    assertEquals(a.size, 3);
    assert (is Integer e0 = a[0]);
    assertEquals(e0, 3);
    assert (is Var e1 = a[1]);
    assertEquals(e1.name, "vv");
    assert (is Integer e2 = a[2]);
    assertEquals(e2, 4);
}

test
shared void testFieldWithStringEnumListArgument()
{
    value enumType = GQLEnumType("Testenum", [GQLEnumValue<>("boing"), GQLEnumValue<>("boam")]);
    value argDef = ArgumentDefinition(GQLInputListType(enumType));
    Schema schema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType, null, map{"true"->argDef})}), null);
    String doc = "{f(true:[boing, $vv, boam])}";
    value parsedDoc = parseDocument(doc, schema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is Field f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is IList<Var|Anything> a = f.arguments["true"]);
    assertEquals(a.size, 3);
    assert (is EnumLiteral e0 = a[0]);
    assertEquals(e0.value_, "boing");
    assert (is Var e1 = a[1]);
    assertEquals(e1.name, "vv");
    assert (is EnumLiteral e2 = a[2]);
    assertEquals(e2.value_, "boam");
}

test
shared void testFieldWithEnumEnumListArgument()
{
    value enumType = GQLEnumType<E>("Testenum", [GQLEnumValue("k", E.kk), GQLEnumValue("l", E.kl)]);
    value argDef = ArgumentDefinition(GQLInputListType(enumType));
    Schema schema = Schema(GQLObjectType("q", {GQLField("f", enumType, null, map{"true"->argDef}, false, null, (a, b) {
        assert (is List<Object?> arg = b["true"]);
        return arg[0];
    })}), null);
    String doc = "{f(true:[k, $vv, l])}";
    value parsedDoc = parseDocument(doc, schema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is Field f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is IList<Var|Anything> a = f.arguments["true"]);
    assertEquals(a.size, 3);
    assert (is EnumLiteral e0 = a[0]);
    assertEquals(e0.value_, "k");
    assert (is Var e1 = a[1]);
    assertEquals(e1.name, "vv");
    assert (is EnumLiteral e2 = a[2]);
    assertEquals(e2.value_, "l");

    value res = schema.executeRequest(parsedDoc);
    value fVal = res.data?.get("f");
    assert (is String fVal);
    assert (fVal == "k");
    print(res);
}

test
shared void testFieldWithObjectArgument()
{
    value argDef = ArgumentDefinition(GQLInputObjectType("o", {GQLInputField("s", gqlStringType), GQLInputField("ff", gqlStringType)}));
    Schema schema = Schema(GQLObjectType("r", {GQLField("f", gqlStringType, null, map({"true"->argDef}))}), null);
    String doc = "{f(true:{s:\"v\", ff:$vvv})}";
    value parsedDoc = parseDocument(doc, schema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is Field f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
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
    Schema schema = Schema(GQLObjectType("t", {GQLField("f1", gqlStringType)}), null);
    String doc = "fragment fr on t { f1 }";
    value parsedDoc = parseDocument(doc, schema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is FragmentDefinition fr = parsedDoc.fragmentDefinition("fr"));
    assertEquals(fr.name, "fr");
    assertEquals(fr.typeCondition, "t");
    value sel = fr.selectionSet.first;
    assert (is Field sel);
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
    String doc = "{ ... {f}}";
    value parsedDoc = parseDocument(doc, simplestSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is InlineFragment inl = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertNull(inl.typeCondition);
    assert (is Field f = inl.selectionSet.first);
    assertEquals(f.name, "f");
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
    Schema schema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType, null, map{"a"->ArgumentDefinition(gqlStringType)})}), null);
    String doc = "query ($v1:String=\"k\"){f(a:$v1)}";
    value parsedDoc = parseDocument(doc, schema);
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
    String doc = "query ($v1:Testenum=popop){f(e:$v)}";
    try {
        value parsedDoc = parseDocument(doc, varSchema);
        if (is ParseError parsedDoc) {
            print(parsedDoc.errorInfos);
            assert (parsedDoc.errorInfos.size == 1);
            assert (parsedDoc.errorInfos.first.message.startsWith("illegal default value <enum literal \"popop\">"));
            return;
        }
        fail("exception expected");
    }
    catch (AssertionError e) {
        print(e.message);
    }
}

test
shared void testStringEnumVariable()
{
    value enumType = GQLEnumType("Testenum", [GQLEnumValue<>("k")]);
    Schema varSchema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType, null, map({"e"->ArgumentDefinition(enumType)}))}), null);
    String doc = "query ($v1:Testenum=k){f(e:$v)}";
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
    value inObjType = GQLInputObjectType("TestInObj", [GQLInputField("k1", gqlStringType), GQLInputField("l1", enumType)]);
    Schema varSchema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType, null, map({"e"->ArgumentDefinition(inObjType)}))}), null);
    String doc = "query ($v1:TestInObj={k1:\"strVal\" l1:l}){f(e:$v1)}";
    value parsedDoc = parseDocument(doc, varSchema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (exists vd = parsedDoc.operationDefinition(null)?.variableDefinitions);
    assertEquals(vd.size, 1);
    assert (exists varDef = vd.get("v1"));
    assertEquals(varDef.type, inObjType);
    assertEquals(varDef.defaultValue, map({"k1"->"strVal", "l1"->E.kl}));
}

test
shared void testStringVariableWithEnumLiteralForbidden()
{
    Schema schema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType, null, map{"a"->ArgumentDefinition(gqlStringType)})}), null);
    String doc = "query ($v1:String=literal){f(a:$v1)}";
    value parsedDoc = parseDocument(doc, schema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        return;
    }
    fail("ParseError expected");
}


test
shared void testFieldSkipDirective()
{
    Schema schema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType)}), null);
    String doc = "{f @skip(if:true)}";
    value parsedDoc = parseDocument(doc, schema);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        fail();
        throw;
    }
    value xx = schema.executeRequest(parsedDoc);
    print(xx);

    assert (is Field fd = parsedDoc.operationDefinition(null)?.selectionSet?.get(0));
    assert (exists dir = fd.directives);
    assertEquals(dir.size, 1);
    assertEquals(dir.first.name, "skip");
    assert (exists args = dir.first.arguments);
    assertEquals(args.size, 1);
    assertEquals(args.first.name, "if");
    assertEquals(args.first.value_, true);
}
