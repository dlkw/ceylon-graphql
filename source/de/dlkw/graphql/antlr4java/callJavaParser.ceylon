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
    DocumentScalarValue,
    Var,
    VariableDefinition,
    Schema
}

import java.util {
    JList=List,
    JArrayList=ArrayList
}
import ceylon.language.meta {
    type
}
import de.dlkw.graphql.exp.types {
    gqlIntType,
    InputCoercing,
    GQLObjectType,
    GQLField,
    gqlStringType,
    undefined,
    Undefined,
    CoercionError
}

shared void run() {
    Schema simplestSchema = Schema(GQLObjectType("q", {GQLField("f", gqlStringType)}), null);
    value result = parseDocument("query\n  1 xuu @a { i:y(i:6) @f { jj:z 2 ... on O{zz}} } fragment a on C { b }", simplestSchema);
    if (is ParseError result) {
        print("\n".join(result.errorInfos));
    }
    else {
        print(result);
    }
}

shared Document|ParseError parseDocument(String documentString, Schema schema)
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
    return createDocument(dc, schema);
}

shared class ParseError(shared [ErrorInfo+] errorInfos){}
shared class ErrorInfo(shared String message, shared Integer line, shared Integer charPositionInLine)
{
    string => "l``line``c``charPositionInLine``: ``message``";
}

Document createDocument(GraphQLParser.DocumentContext documentContext, Schema schema)
{
    return Document(createDefinitions(documentContext.definition(), schema));
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

[OperationDefinition | FragmentDefinition*] createDefinitions(JList<GraphQLParser.DefinitionContext> definitionContexts, Schema schema)
{
    return { for (definitionContext in definitionContexts) if (exists oc = definitionContext.operationDefinition()) then createOperationDefinition(oc, schema) else createFragmentDefinition(definitionContext.fragmentDefinition())}.sequence();
}

OperationDefinition createOperationDefinition(GraphQLParser.OperationDefinitionContext operationDefinitionContext, Schema schema)
{
    String? name = operationDefinitionContext.name()?.text;
    value parsedOperationType = operationDefinitionContext.operationType();
    OperationType type = if (is Null parsedOperationType)
        then OperationType.query
        else (parsedOperationType.text == "query" then OperationType.query else OperationType.mutation);

    value variableDefinitions = createVariableDefinitions(operationDefinitionContext.variableDefinitions(), schema);

    value directives = createDirectives(operationDefinitionContext.directives());
    value selectionSet = createSelectionSet(operationDefinitionContext.selectionSet());
    return OperationDefinition(type, selectionSet, name, variableDefinitions);
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

Anything | Var convertValueOrVariable(GraphQLParser.ValueOrVariableContext valueOrVariableContext) {
    if (exists var = valueOrVariableContext.variable()) {
        return Var(var.name().text);
    }
    assert (exists val = valueOrVariableContext.\ivalue());

    return convertValue(val);
}

Anything convertValue(GraphQLParser.ValueContext val)
{
    Anything value_;
    switch (val)
    case (is GraphQLParser.StringValueContext) {
        value_ = val.text.removeInitial("\"").removeTerminal("\"");
    }
    case (is GraphQLParser.NumberValueContext) {
        value s = val.text;
        if (s.containsAny({'.', 'e', 'E'})) {
            assert (is Float f = Float.parse(s));
            value_ = f;
        }
        else {
            assert (is Integer i = Integer.parse(s));
            value_ = i;
        }
    }
    case (is GraphQLParser.NullValueContext) {
        value_ = null;
    }
    case (is GraphQLParser.BooleanValueContext) {
        value_ = val.text == "true";
    }
    case (is GraphQLParser.EnumValueContext) {
        value_ = val.text;
    }
    case (is GraphQLParser.ArrayValueContext) {
        value_ = [ for (valOrVar in val.array().valueOrVariable()) convertValueOrVariable(valOrVar) ];
    }
    case (is GraphQLParser.ObjectValueContext) {
        value_ = map({ for (arg in val.\iobject().argument()) arg.name().text -> convertValueOrVariable(arg.valueOrVariable()) });
    }
    else {
        throw AssertionError("could not create argument of type ``type(val)``");
    }
    return value_;
}

Argument createArgument(GraphQLParser.ArgumentContext argumentContext)
{

    String name = argumentContext.name().text;
    value x = argumentContext.valueOrVariable();
    Anything | Var value_ = convertValueOrVariable(x);
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

[<String->VariableDefinition<Object, String?>>+]? createVariableDefinitions(GraphQLParser.VariableDefinitionsContext variableDefinitionsContext, Schema schema)
{
    value variableDefinitions = [ for (variableDefinitionContext in variableDefinitionsContext.variableDefinition()) variableDefinitionContext.variable().name().text -> createVariableDefinition(variableDefinitionContext, schema) ];
    assert (nonempty variableDefinitions);
    return variableDefinitions;

}

VariableDefinition<Object, String?> createVariableDefinition(GraphQLParser.VariableDefinitionContext variableDefinitionContext, Schema schema)
{
    value x = variableDefinitionContext.type().typeName().text;
    value registeredType = schema.lookupType(x);
    if (!is InputCoercing<String, Anything, Nothing> registeredType) {
        throw;
    }
    value c1 = variableDefinitionContext.defaultValue();
    Object?|Undefined defaultValue;
    if (is Null c1) {
        defaultValue = undefined;
    }
    else {
        value c2 = c1.\ivalue();
        // FIXME prevent var in list or object value
        value inputValue = convertValue(c2);
        defaultValue = registeredType.coerceInput(inputValue) of Object?;
        if (is CoercionError defaultValue) {
            if (is Null inputValue) {
                throw AssertionError("cannot happen");
            }
            throw AssertionError("illegal default value <``inputValue``> for variable of type ``registeredType``");
        }
    }
    // FIXME first type parameter should be set dynamically according to type of c2
    return VariableDefinition<Object, String>(registeredType, defaultValue);
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
