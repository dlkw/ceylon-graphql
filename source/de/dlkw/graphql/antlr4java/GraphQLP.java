package de.dlkw.graphql.antlr4java;

import de.dlkw.graphql.antlr4java.generated.GraphQLLexer;
import de.dlkw.graphql.antlr4java.generated.GraphQLParser;
import org.antlr.v4.runtime.*;

import java.util.List;

public class GraphQLP
{
    public GraphQLParser.DocumentContext parseDocument(String document, final List<ErrorInfo> errors)
    {
        ANTLRInputStream in = new ANTLRInputStream(document);
        GraphQLLexer lexer = new GraphQLLexer(in);
        CommonTokenStream tokens = new CommonTokenStream(lexer);
        GraphQLParser parser = new GraphQLParser(tokens);

        parser.removeErrorListeners();
        parser.addErrorListener(new BaseErrorListener() {
            @Override
            public void syntaxError(Recognizer<?, ?> recognizer, Object offendingSymbol, int line, int charPositionInLine, String msg, RecognitionException e) {
                errors.add(new ErrorInfo(msg, line, charPositionInLine));
            }
        });

        return parser.document();
    }

    public static class ErrorInfo
    {
        public final String message;
        public final int line;
        public final int charPositionInLine;
        public ErrorInfo(String message, int line, int charPositionInLine)
        {
            this.message = message;
            this.line = line;
            this.charPositionInLine = charPositionInLine;
        }
    }
}
