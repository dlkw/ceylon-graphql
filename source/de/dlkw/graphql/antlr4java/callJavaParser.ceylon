import ceylon.language.meta {
    type
}

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
    Var,
    VariableDefinition,
    Schema,
    DocumentValue,
    EnumLiteral,
    IObject,
    IList
}
import de.dlkw.graphql.exp.types {
    GQLObjectType,
    GQLField,
    gqlStringType,
    undefined,
    Undefined,
    CoercionError,
    InputCoercingBase,
    GQLObjectTypeWithAdditionalFields
}

import java.util {
    JList=List,
    JArrayList=ArrayList
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
        value errorInfos = { for (jErrorInfo in errors) ErrorInfo(jErrorInfo.message, jErrorInfo.line, jErrorInfo.charPositionInLine + 1) }.sequence();
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

Document | ParseError createDocument(GraphQLParser.DocumentContext documentContext, Schema schema)
{
    value definitions = createDefinitions(documentContext.definition(), schema);
    if (is ParseError definitions) {
        return definitions;
    }
    return Document(definitions);
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

[OperationDefinition | FragmentDefinition*] | ParseError createDefinitions(JList<GraphQLParser.DefinitionContext> definitionContexts, Schema schema)
{
    value result = { for (definitionContext in definitionContexts)
        if (exists oc = definitionContext.operationDefinition())
            then createOperationDefinition(oc, schema)
            else createFragmentDefinition(definitionContext.fragmentDefinition())}
        .sequence();

    value allErrorInfos = result.narrow<ParseError>().flatMap((err) => err.errorInfos).sequence();
    if (nonempty allErrorInfos) {
        return ParseError(allErrorInfos);
    }

    return [ for (r in result) if (!is ParseError r) r ];
}

OperationDefinition | ParseError createOperationDefinition(GraphQLParser.OperationDefinitionContext operationDefinitionContext, Schema schema)
{
    String? name = operationDefinitionContext.name()?.text;
    value parsedOperationType = operationDefinitionContext.operationType();
    OperationType type = if (is Null parsedOperationType)
        then OperationType.query
        else (parsedOperationType.text == "query" then OperationType.query else OperationType.mutation);

    GQLObjectType rootType;
    if (type == OperationType.query) {
        rootType = schema.queryRoot;
    }
    else {
        assert (exists mutationRoot = schema.mutationRoot);
        rootType = mutationRoot;
    }

    value variableDefinitionsContext = operationDefinitionContext.variableDefinitions();
    value variableDefinitions = if (exists variableDefinitionsContext)
        then createVariableDefinitions(variableDefinitionsContext, schema)
        else null;

    value directives = createDirectives(operationDefinitionContext.directives());
    value selectionSet = createSelectionSet(operationDefinitionContext.selectionSet());

    variable ErrorInfo[] errorInfos = [];

    if (is ParseError variableDefinitions) {
        errorInfos = errorInfos.append(variableDefinitions.errorInfos);
    }

    if (is ParseError selectionSet) {
        errorInfos = errorInfos.append(selectionSet.errorInfos);
    }

    if (nonempty ei = errorInfos) {
        return ParseError(ei);
    }

    assert (!is ParseError variableDefinitions);
    assert (!is ParseError selectionSet);

    return OperationDefinition(type, selectionSet, name, variableDefinitions);
}

DocumentValue<V> convertValueOrVariable<V>(GraphQLParser.ValueOrVariableContext valueOrVariableContext)
    given V satisfies Var
{
    if (exists varContext = valueOrVariableContext.variable()) {
        value var = Var(varContext.name().text);
        // prevent variables when only values are allowed
        assert (is V var); // FIXME do error
        return var;
    }
    assert (exists val = valueOrVariableContext.\ivalue());

    return convertValue<V>(val);
}

// this will never return a Var
// but it's easier to include the V in the DocumentValue union cases
DocumentValue<V> convertValue<V>(GraphQLParser.ValueContext val)
    given V satisfies Var
{
    DocumentValue<V> value_;
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
        value_ = EnumLiteral(val.text);
    }
    case (is GraphQLParser.ArrayValueContext) {
        value_ = IList<V>([ for (valOrVar in val.array().valueOrVariable()) convertValueOrVariable<V>(valOrVar) ]);
    }
    case (is GraphQLParser.ObjectValueContext) {
        value_ = IObject<V>({ for (arg in val.\iobject().argument()) arg.name().text -> convertValueOrVariable<V>(arg.valueOrVariable()) });
    }
    else {
        throw AssertionError("could not create argument of type ``type(val)``");
    }
    return value_;
}

Argument | ParseError createArgument(GraphQLParser.ArgumentContext argumentContext)
{
    String name = argumentContext.name().text;
    value valueOrVariableContext = argumentContext.valueOrVariable();
    DocumentValue<Var> | Var converted = convertValueOrVariable<Var>(valueOrVariableContext);
    return Argument(name, converted);
}

[Argument+]? | ParseError createArguments(GraphQLParser.ArgumentsContext? argumentsContext)
{
    if (is Null argumentsContext) {
        return null;
    }
    value arguments = { for (argumentContext in argumentsContext.argument()) createArgument(argumentContext) }.sequence();
    assert (nonempty arguments);

    value allErrorInfos = { for (v in arguments) if (is ParseError v) v}.flatMap((err) => err.errorInfos).sequence();
    if (nonempty allErrorInfos) {
        return ParseError(allErrorInfos);
    }

    value result = [ for (r in arguments) if (!is ParseError r) r ];
    assert (nonempty result);
    return result;
}

alias OT => GQLObjectType|GQLObjectTypeWithAdditionalFields;

[Selection+] | ParseError createSelectionSet(GraphQLParser.SelectionSetContext selectionSetContext)
{
    value selectionSet = { for (selCtx in selectionSetContext.selection()) createSelection(selCtx) }.sequence();

    value allErrorInfos = { for (v in selectionSet) if (is ParseError v) v}.flatMap((err) => err.errorInfos).sequence();
    if (nonempty allErrorInfos) {
        return ParseError(allErrorInfos);
    }

    value result = [ for (r in selectionSet) if (!is ParseError r) r ];
    assert (nonempty result);
    return result;
}

Selection | ParseError createSelection(GraphQLParser.SelectionContext selCtx)
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

Field | ParseError createField(GraphQLParser.FieldContext fieldContext)
{
    String fieldName;
    String? fieldAlias;
    if (exists aliasContext = fieldContext.fieldName().\ialias()) {
        fieldAlias = aliasContext.name().get(0).text;
        fieldName = aliasContext.name().get(1).text;
    }
    else {
        fieldAlias = null;
        value fieldNameContext = fieldContext.fieldName();
        fieldName = fieldNameContext.name().text;
    }

    value directives = createDirectives(fieldContext.directives());
    value arguments = createArguments(fieldContext.arguments());

    value selectionSetContext = fieldContext.selectionSet();
    [Selection+]? | ParseError selectionSet;
    if (exists selectionSetContext) {
        selectionSet = createSelectionSet(selectionSetContext);
    }
    else {
        selectionSet = null;
    }

    variable value errorInfos = exQ(arguments, []);
    errorInfos = exQ(directives, []);
    errorInfos = exQ(selectionSet, errorInfos);

    if (nonempty ei = errorInfos) {
        return ParseError(ei);
    }

    assert (!is ParseError arguments);
    assert (!is ParseError directives);
    assert (!is ParseError selectionSet);

    return Field(fieldName, fieldAlias, arguments, directives, selectionSet);
}

[A+]? | ParseError exP<A>({A|ParseError*} f)
{
    value allErrorInfos = { for (v in f) if (is ParseError v) v}.flatMap((err) => err.errorInfos).sequence();
    if (nonempty allErrorInfos) {
        return ParseError(allErrorInfos);
    }

    value result = [ for (r in f) if (!is ParseError r) r ];
    assert (nonempty result);
    return result;
}

ErrorInfo[] exQ<A>([A+]?|ParseError ii, variable ErrorInfo[] ee)
{
    if (is ParseError ii) {
        return ee.append(ii.errorInfos);
    }
    return ee;
}

FragmentDefinition | ParseError createFragmentDefinition(GraphQLParser.FragmentDefinitionContext fragmentDefinitionContext)
{
    String name = fragmentDefinitionContext.fragmentName().name().text;
    // maybe the following is enough: fragmentDefinitionContext.typeCondition().text;
    String typeCondition = fragmentDefinitionContext.typeCondition().typeName().name().text;

    value directives = createDirectives(fragmentDefinitionContext.directives());

    value selectionSet = createSelectionSet(fragmentDefinitionContext.selectionSet());

    variable value errorInfos = exQ(directives, []);
    errorInfos = exQ(selectionSet, errorInfos);
    if (nonempty ei = errorInfos) {
        return ParseError(ei);
    }
    assert (!is ParseError directives);
    assert (!is ParseError selectionSet);

    return FragmentDefinition(name, selectionSet, typeCondition, directives);
}

FragmentSpread | ParseError createFragmentSpread(GraphQLParser.FragmentSpreadContext fragmentSpreadContext)
{
    value name = fragmentSpreadContext.fragmentName().name().text;
    value directives = createDirectives(fragmentSpreadContext.directives());
    if (is ParseError directives) {
        return directives;
    }
    return FragmentSpread(name, directives);
}

InlineFragment | ParseError createInlineFragment(GraphQLParser.InlineFragmentContext inlineFragmentContext)
{
    String? typeCondition = inlineFragmentContext.typeCondition()?.typeName()?.name()?.text;
    value directives = createDirectives(inlineFragmentContext.directives());
    value selectionSet = createSelectionSet(inlineFragmentContext.selectionSet());

    variable value errorInfos = exQ(directives, []);
    errorInfos = exQ(selectionSet, errorInfos);
    if (nonempty ei = errorInfos) {
        return ParseError(ei);
    }
    assert (!is ParseError directives);
    assert (!is ParseError selectionSet);

    return InlineFragment(selectionSet, typeCondition, directives);
}

[<String->VariableDefinition<Object, String?>>+] | ParseError createVariableDefinitions(GraphQLParser.VariableDefinitionsContext variableDefinitionsContext, Schema schema)
{
    value variableDefinitions = [ for (variableDefinitionContext in variableDefinitionsContext.variableDefinition())
        let (varDef = createVariableDefinition(variableDefinitionContext, schema))
        if (is ParseError varDef)
            then variableDefinitionContext.variable().name().text -> varDef
            else variableDefinitionContext.variable().name().text -> varDef];
    value allErrorInfos = { for (v in variableDefinitions) if (is ParseError e = v.item) e}.flatMap((err) => err.errorInfos).sequence();
    if (nonempty allErrorInfos) {
        return ParseError(allErrorInfos);
    }

    value result = [ for (r in variableDefinitions) if (!is String->ParseError r) r ];
    assert (nonempty result);
    return result;
}

VariableDefinition<Object, String?> | ParseError createVariableDefinition(GraphQLParser.VariableDefinitionContext variableDefinitionContext, Schema schema)
{
    value x = variableDefinitionContext.type().typeName().text;
    value registeredType = schema.lookupType(x);
    if (!is InputCoercingBase<String, Anything> registeredType) {
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
        // FIXME prevent enum value literal for non-enum types
        value inputValue = convertValue<Nothing>(c2);
        defaultValue = registeredType.coerceInput(inputValue) of Object?;
        if (is CoercionError defaultValue) {
            if (is Null inputValue) {
                throw AssertionError("cannot happen");
            }
            return ParseError([ErrorInfo("illegal default value <``inputValue``> for variable of type ``registeredType``: ``defaultValue.message``", variableDefinitionContext.start.line, variableDefinitionContext.start.charPositionInLine + 1)]);
        }
    }
    // FIXME first type parameter should be set dynamically according to type of c2
    return VariableDefinition<Object, String>(registeredType, defaultValue);
}

[Directive+]? | ParseError createDirectives(GraphQLParser.DirectivesContext? directivesContext)
{
    if (is Null directivesContext) {
        return null;
    }

    value directives = exP({ for (directiveContext in directivesContext.directive()) createDirective(directiveContext) });
    return directives;
}

Directive | ParseError createDirective(GraphQLParser.DirectiveContext directiveContext)
{
    value name = directiveContext.name().text;
    value argumentsContext = directiveContext.arguments();
    if (exists argumentsContext) {
        value arguments = exP({ for (argumentContext in argumentsContext.argument()) createArgument(argumentContext) });
        if (is ParseError arguments) {
            return arguments;
        }
        return Directive(name, arguments);
    }
    else {
        return Directive(name, null);
    }
}
