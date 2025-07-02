/**
 * The testing module defines helper methods for testing your HTTP handling
 * code.
 */
module handy_http_primitives.testing;

import handy_http_primitives.response;

/**
 * Asserts that the given response's status matches an expected status.
 * Params:
 *   response = The response to check.
 *   expectedStatus = The expected status that the response should have.
 */
void assertStatus(in ServerHttpResponse response, in StatusInfo expectedStatus) {
    import std.format : format;
    assert(
        expectedStatus == response.status,
        format!"The HTTP response's status of %d (%s) didn't match the expected status %d (%s)."(
            response.status.code,
            response.status.text,
            expectedStatus.code,
            expectedStatus.text
        )
    );
}

unittest {
    import handy_http_primitives.builder;
    ServerHttpResponseBuilder()
        .withStatus(HttpStatus.OK)
        .build()
        .assertStatus(HttpStatus.OK);
}

// Some common status assertions:

void assertStatusOk(in ServerHttpResponse response) {
    assertStatus(response, HttpStatus.OK);
}

void assertStatusNotFound(in ServerHttpResponse response) {
    assertStatus(response, HttpStatus.NOT_FOUND);
}

void assertStatusBadRequest(in ServerHttpResponse response) {
    assertStatus(response, HttpStatus.BAD_REQUEST);
}

void assertStatusUnauthorized(in ServerHttpResponse response) {
    assertStatus(response, HttpStatus.UNAUTHORIZED);
}

void assertStatusForbidden(in ServerHttpResponse response) {
    assertStatus(response, HttpStatus.FORBIDDEN);
}

void assertStatusInternalServerError(in ServerHttpResponse response) {
    assertStatus(response, HttpStatus.FORBIDDEN);
}

/**
 * Asserts that the given response has a header with a given value.
 * Params:
 *   response = The response to check.
 *   header = The name of the header to check the value of.
 *   expectedValue = The expected value of the header.
 */
void assertHasHeader(in ServerHttpResponse response, string header, string expectedValue) {
    import std.format : format;
    assert(
        response.headers.contains(header),
        format!"The HTTP response doesn't have a header named \"%s\"."(header)
    );
    string value = response.headers.getFirst(header).orElseThrow();
    assert(
        value == expectedValue,
        format!"The HTTP response's header \"%s\" with value \"%s\" didn't match the expected value \"%s\"."(
            header,
            value,
            expectedValue
        )
    );
}

unittest {
    import streams;
    import handy_http_primitives.builder;
    ArrayOutputStream!ubyte bufferOut = byteArrayOutputStream();
    ServerHttpResponse r1 = ServerHttpResponseBuilder()
        .withOutputStream(&bufferOut)
        .build();
    r1.writeBodyString("Hello, world!");
    r1.assertHasHeader("Content-Type", ContentTypes.TEXT_PLAIN);
}
