# ceylon-graphql
A GraphQL server engine written in the Ceylon programming language.

The core part is written in Ceylon.

The document parsing is implemented using ANTLR-4 for Java as I could not find a parsing framework with a Ceylon runtime.
I'd definitely like to know if/when there is one!

## Implementation progress notes

The implementation is based on the current available version of the GraphQL specification (as of 2017-03-03, this is the
October 2016 working draft) found [here](http://facebook.github.io/graphql/).

### Parsing phase

Parsing is done using a modified version of the GraphQL example coming with ANTLR-4's.
I didn't put much effort into doing it right or optimizing it, just modified the
example to support the spec.

### Validation phase

The Validation phase is not implemented at all yet, so please be careful.

### Execution phase

This is pretty much working, using serial execution only.
At the moment, it's a big paradigm issue how to implement some framework or library in Ceylon:
Should it generally be implemented using some async/event loop approach or just in a "JVM conventional"
call-and-return-result way? This may be discussed in issue#3.

In several places errors during execution just throw instead of nicely presenting the error in the GraphQL response. This is
the next thing to tackle.

Introspection is working in large parts, but there may still be things missing. Need to check/test.
The schemas tested so far provide the correct documentation when examined using the GraphiQL front end tool.

## Extensions to the GraphQL specification

The error structure includes a "path" field that shows the exact place of the field in the result data that raised an
error, including index number of items in LISTs in square brackets like `toplevel/list[0]/leaf`.
