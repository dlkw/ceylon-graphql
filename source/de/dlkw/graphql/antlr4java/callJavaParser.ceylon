import de.dlkw.graphql.antlr4java.generated {
    GraphQLParser
}

import de.dlkw.graphql.exp {
    OperationType,
    Selection,
    FragmentSpread,
    Directive,
    InlineFragment,
    OperationDefinition,
    Document,
    FragmentDefinition,
    Field,
    Argument,
    DocumentScalarValue
}

import java.util {
    JList=List,
    JArrayList=ArrayList
}
import ceylon.language.meta {
    type
}

shared void run() {
    value result = parseDocument("query\n  1 xuu @a { i:y(i:6) @f { jj:z 2 ... on O{zz}} } fragment a on C { b }");
    if (is ParseError result) {
        print("\n".join(result.errorInfos));
    }
    else {
        print(result);
    }
}

shared Document|ParseError parseDocument(String documentString)
{
    GraphQLP p = GraphQLP();

    JList<GraphQLP.ErrorInfo> errors = JArrayList<GraphQLP.ErrorInfo>();

    GraphQLParser.DocumentContext dc = p.parseDocument(documentString, errors);
    if (!errors.empty) {
        // don't want to introduce an API module for an ErrorInfo interface (yet), so map the structures for now.
        value errorInfos = { for (jErrorInfo in errors) ErrorInfo(jErrorInfo.message, jErrorInfo.line, jErrorInfo.charPositionInLine) }.sequence();
        assert (nonempty errorInfos);
        return ParseError(errorInfos);
    }
    return createDocument(dc);
}

shared class ParseError(shared [ErrorInfo+] errorInfos){}
shared class ErrorInfo(shared String message, shared Integer line, shared Integer charPositionInLine)
{
    string => "l``line``c``charPositionInLine``: ``message``";
}

Document createDocument(GraphQLParser.DocumentContext documentContext)
{
    return Document(createDefinitions(documentContext.definition()));
/*
    shared actual IOperationDefinition? operationDefinition(String? name)
    {
        if (exists name) {
            return operationDefinitions.filter((oDef)=>oDef.name?.equals(name) else false).first;
        }
        else if (operationDefinitions.shorterThan(2)) {
            return operationDefinitions.first;
        }
        else {
            throw AssertionError("Operation name must be specified if document contains more than one operation.");
        }
    }

    shared actual IFragmentDefinition? fragmentDefinition(String name) =>
            fragmentDefinitions.filter((fDef)=>fDef.name.equals(name)).first;
*/
}

[OperationDefinition | FragmentDefinition*] createDefinitions(JList<GraphQLParser.DefinitionContext> definitionContexts)
{
    return { for (definitionContext in definitionContexts) if (exists oc = definitionContext.operationDefinition()) then createOperationDefinition(oc) else createFragmentDefinition(definitionContext.fragmentDefinition())}.sequence();
}

OperationDefinition createOperationDefinition(GraphQLParser.OperationDefinitionContext operationDefinitionContext)
{
    String? name = operationDefinitionContext.name()?.text;
    value parsedOperationType = operationDefinitionContext.operationType();
    OperationType type = if (is Null parsedOperationType)
        then OperationType.query
        else (parsedOperationType.text == "query" then OperationType.query else OperationType.mutation);

    value directives = createDirectives(operationDefinitionContext.directives());
    value selectionSet = createSelectionSet(operationDefinitionContext.selectionSet());
    return OperationDefinition(type, selectionSet, name);
}

Selection createSelection(GraphQLParser.SelectionContext selCtx)
{
    if (exists fieldCtx = selCtx.field()) {
        return createField(fieldCtx);
    }
    else if (exists fragmentSpreadCtx = selCtx.fragmentSpread()) {
        return createFragmentSpread(fragmentSpreadCtx);
    }
    assert (exists inlineFragmentCtx = selCtx.inlineFragment());
    return createInlineFragment(inlineFragmentCtx);
}

Argument createArgument(GraphQLParser.ArgumentContext argumentContext)
{
    String name = argumentContext.name().text;
    value x = argumentContext.valueOrVariable().\ivalue();
    Anything value_;
    switch (x)
    case (is GraphQLParser.StringValueContext) {
        value_ = x.text.removeInitial("\"").removeTerminal("\"");
    }
    case (is GraphQLParser.NullValueContext) {
        value_ = null;
    }
    case (is GraphQLParser.BooleanValueContext) {
        value_ = x.text == "true";
    }
    case (is GraphQLParser.EnumValueContext) {
        value_ = x.text;
    }
    case (is GraphQLParser.ArrayValueContext) {
        value_ = [ for (ctx in x.array().\ivalue()) ctx.text.removeInitial("\"").removeTerminal("\"") ];
    }
    else {
        throw AssertionError("could not create argument of type ``type(x)``");
    }
    return Argument(name, value_);
}

[Argument+]? createArguments(GraphQLParser.ArgumentsContext? argumentsContext)
{
    if (is Null argumentsContext) {
        return null;
    }
    value arguments = { for (argumentContext in argumentsContext.argument()) createArgument(argumentContext) }.sequence();
    assert (nonempty arguments);
    return arguments;
}

[Selection+]|Absent createSelectionSet<Absent>(GraphQLParser.SelectionSetContext|Absent selectionSetContext)
    given Absent satisfies Null
{
    if (is Absent selectionSetContext) {
        // following returns null
        return selectionSetContext;
    }
    value selectionSet = { for (selCtx in selectionSetContext.selection()) createSelection(selCtx) }.sequence();
    assert (nonempty selectionSet);
    return selectionSet;
}

FragmentDefinition createFragmentDefinition(GraphQLParser.FragmentDefinitionContext fragmentDefinitionContext)
{
    String name = fragmentDefinitionContext.fragmentName().name().text;
    // maybe the following is enough: fragmentDefinitionContext.typeCondition().text;
    String typeCondition = fragmentDefinitionContext.typeCondition().typeName().name().text;
    [Selection+] selectionSet = createSelectionSet(fragmentDefinitionContext.selectionSet());
    return FragmentDefinition(name, selectionSet, typeCondition);
}

FragmentSpread createFragmentSpread(GraphQLParser.FragmentSpreadContext fragmentSpreadContext)
{
    value name = fragmentSpreadContext.fragmentName().name().text;
    value directives = createDirectives(fragmentSpreadContext.directives());
    return FragmentSpread(name, directives);
}

InlineFragment createInlineFragment(GraphQLParser.InlineFragmentContext inlineFragmentContext)
{
    value selectionSet = createSelectionSet(inlineFragmentContext.selectionSet());
    String? typeCondition = inlineFragmentContext.typeCondition()?.typeName()?.name()?.text;
    value directives = createDirectives(inlineFragmentContext.directives());
    return InlineFragment(selectionSet, typeCondition, directives);
}

[Directive+]? createDirectives(GraphQLParser.DirectivesContext? directivesContext)
{
    if (is Null directivesContext) {
        return null;
    }

    value directives = { for (directiveContext in directivesContext.directive()) createDirective(directiveContext) }.sequence();
    assert (nonempty directives);
    return directives;
}

Directive createDirective(GraphQLParser.DirectiveContext directiveContext)
{
    return Directive();
}

Field createField(GraphQLParser.FieldContext fieldContext)
{
    value directives = createDirectives(fieldContext.directives());
    value arguments = createArguments(fieldContext.arguments());
    value selectionSet = createSelectionSet<Null>(fieldContext.selectionSet());
    if (exists aliasContext = fieldContext.fieldName().\ialias()) {
        String alias_ = aliasContext.name().get(0).text;
        String name = aliasContext.name().get(1).text;
        return Field(name, alias_, arguments, directives, selectionSet);
    }
    value fieldNameContext = fieldContext.fieldName();
    value name = fieldNameContext.name().text;
    return Field(name, null, arguments, directives, selectionSet);
}
