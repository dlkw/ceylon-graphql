# ceylon-graphql
A GraphQL server engine written in the Ceylon programming language.

The core part is written in Ceylon.

The document parsing is implemented using ANTLR-4 for Java as I could not find a parsing framework with a Ceylon runtime.
I'd definitely like to know if/when there is one!

## Implementation progress notes

The implementation is based on the current available version of the GraphQL specification (as of 2017-03-03, this is the
October 2016 working draft) found [here](http://facebook.github.io/graphql/).

Execution is pretty much complete.

In several places errors during execution just throw instead of nicely presenting the error in the GraphQL response. This is
the next thing to tackle.

Validation is not implemented at all yet, so please be careful.

Introspection is working in large parts, but there may still be things missing. Need to check/test.
The schemas tested so far provide the correct documentation when examined using the GraphiQL front end tool.

## Extensions to the GraphQL specification

The error structure includes a "path" field that shows the exact place of the field in the result data that raised an
error, including index number of items in LISTs in square brackets like "toplevel/list[0]/leaf".
