import ceylon.test {
    test,
    assertEquals,
    assertNull,
    assertTrue,
    assertFalse
}

import de.dlkw.graphql.antlr4java {
    parseDocument,
    ParseError,
    Val,
    Var
}
import de.dlkw.graphql.exp {
    OperationType,
    AField,
    FragmentDefinition,
    FragmentSpread,
    InlineFragment
}

test
shared void testAnonymousQuery()
{
    String doc = "{ f }";
    value parsedDoc = parseDocument(doc);
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
    value parsedDoc = parseDocument(doc);
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
    value parsedDoc = parseDocument(doc);
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
shared void testNamedMutation()
{
    String doc = "mutation q { f }";
    value parsedDoc = parseDocument(doc);
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
    value parsedDoc = parseDocument(doc);
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
    value parsedDoc = parseDocument(doc);
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
    value parsedDoc = parseDocument(doc);
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
    value parsedDoc = parseDocument(doc);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is AField f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is Val a = f.arguments["null"]);
    assertEquals(a.val, "o8");
}

test
shared void testFieldWithNullArgument()
{
    String doc = "{f(a:null)}";
    value parsedDoc = parseDocument(doc);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is AField f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is Val a = f.arguments.get("a"));
    assertNull(a.val);
}

test
shared void testFieldWithTrueArgument()
{
    String doc = "{f(a:true)}";
    value parsedDoc = parseDocument(doc);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is AField f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is Val a = f.arguments["a"]);
    assertEquals(a.val, true);
}

test
shared void testFieldWithFalseArgument()
{
    String doc = "{f(a:false)}";
    value parsedDoc = parseDocument(doc);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is AField f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is Val a = f.arguments["a"]);
    assertEquals(a.val, false);
}

test
shared void testFieldWithEnumArgument()
{
    String doc = "{f(true:boing)}";
    value parsedDoc = parseDocument(doc);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is AField f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is Val a = f.arguments["true"]);
    assertEquals(a.val, "boing");
}

test
shared void testFieldWithIntArgument()
{
    String doc = "{f(true:5)}";
    value parsedDoc = parseDocument(doc);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is AField f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is Val a = f.arguments["true"]);
    assert (is Integer b = a.val);
    assertEquals(a.val, 5);
}

test
shared void testFieldWithFloatArgument()
{
    String doc = "{f(true:5.1)}";
    value parsedDoc = parseDocument(doc);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is AField f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is Val a = f.arguments["true"]);
    assertEquals(a.val, 5.1);
}

test
shared void testFieldWithListArgument()
{
    String doc = "{f(true:[3, $vv, \"4\"])}";
    value parsedDoc = parseDocument(doc);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is AField f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is Val a = f.arguments["true"]);
    assert (is Sequence<Val|Var> s = a.val);
    assertEquals(s.size, 3);
    assert (is Val e0 = s[0]);
    assertEquals(e0.val, 3);
    assert (is Var e1 = s[1]);
    assertEquals(e1.name, "vv");
    assert (is Val e2 = s[2]);
    assertEquals(e2.val, "4");
}

test
shared void testFieldWithObjectArgument()
{
    String doc = "{f(true:{s:\"v\", ff:$vvv})}";
    value parsedDoc = parseDocument(doc);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is AField f = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertEquals(f.arguments.size, 1);
    assert (is Val a = f.arguments["true"]);
    assert (is Map<> m = a.val);
    assertEquals(m.size, 2);
    value s = m.get("s");
    assert (is Val s);
    assertEquals(s.val, "v");
    value ff = m.get("ff");
    assert (is Var ff);
    assertEquals(ff.name, "vvv");
}

test
shared void testFragmentDefinition()
{
    String doc = "fragment fr on t { f1 }";
    value parsedDoc = parseDocument(doc);
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
    value parsedDoc = parseDocument(doc);
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
    value parsedDoc = parseDocument(doc);
    if (is ParseError parsedDoc) {
        print(parsedDoc.errorInfos);
        throw;
    }

    assert (is InlineFragment inl = parsedDoc.operationDefinition(null)?.selectionSet?.first);
    assertNull(inl.typeCondition);
    assert (is AField sf1 = inl.selectionSet.first);
    assertEquals(sf1.name, "sf1");
}
