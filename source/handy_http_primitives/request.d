/**
 * Defines the request structure and associated types that are generally used
 * when dealing with a client's HTTP request.
 */
module handy_http_primitives.request;

import streams;
import std.traits : EnumMembers;

import handy_http_primitives.optional;
import handy_http_primitives.address;

/**
 * The HTTP request struct which represents the content of an HTTP request as
 * received by a server.
 */
struct ServerHttpRequest {
    /// The HTTP version of the request.
    const HttpVersion httpVersion = HttpVersion.V1;
    /// The remote address of the client that sent this request.
    const ClientAddress clientAddress = ClientAddress.unknown;
    /// The HTTP verb used in the request.
    const string method = HttpMethod.GET;
    /// The URL that was requested, excluding any query parameters.
    const string url = "";
    /// A case-insensitive map of all request headers.
    const(string[][string]) headers;
    /// A list of all URL query parameters.
    const QueryParameter[] queryParams;
    /// The underlying stream used to read the body from the request.
    InputStream!ubyte inputStream;
    /// Any additional data about this request that may be populated during handling.
    Object[string] contextData;

    /**
     * Gets a header as the specified type, or returns the default value if the
     * header doesn't exist or cannot be converted to the desired type.
     * Params:
     *   headerName = The name of the header to get, case-sensitive.
     *   defaultValue = The default value to return if the header doesn't exist
     *                  or is invalid.
     * Returns: The header value.
     */
    T getHeaderAs(T)(string headerName, T defaultValue = T.init) const {
        import std.conv : to, ConvException;
        if (headerName !in headers || headers[headerName].length == 0) return defaultValue;
        try {
            return to!T(headers[headerName][0]);
        } catch (ConvException e) {
            return defaultValue;
        }
    }

    /**
     * Gets a query parameter with a given name, as the specified type, or
     * returns the default value if the parameter doesn't exist.
     * Params:
     *   paramName = The name of the parameter to get.
     *   defaultValue = The default value to return if the parameter doesn't
     *                  exist or is invalid.
     * Returns: The parameter value.
     */
    T getParamAs(T)(string paramName, T defaultValue = T.init) const {
        import std.conv : to, ConvException;
        foreach (ref param; queryParams) {
            if (param.key == paramName) {
                foreach (string value; param.values) {
                    try {
                        return value.to!T;
                    } catch (ConvException e) {
                        continue;
                    }
                }
                // No value could be converted, short-circuit now.
                return defaultValue;
            }
        }
        return defaultValue;
    }

    /**
     * Reads the body of this request and transfers it to the given output
     * stream, limited by the request's "Content-Length" unless you choose to
     * allow infinite reading. If the request includes a header for
     * "Transfer-Encoding: chunked", then it will wrap the input stream in one
     * which decodes HTTP chunked-encoding first.
     * Params:
     *   outputStream = The output stream to transfer data to.
     *   allowInfiniteRead = Whether to allow reading the request even if the
     *                       Content-Length header is missing or invalid. Use
     *                       with caution!
     * Returns: Either the number of bytes read, or a stream error.
     */
    StreamResult readBody(S)(ref S outputStream, bool allowInfiniteRead = false) if (isByteOutputStream!S) {
        import std.algorithm : min;
        import std.string : toLower;
        const long contentLength = getHeaderAs!long("Content-Length", -1);
        if (contentLength < 0 && !allowInfiniteRead) {
            return StreamResult(0);
        }
        InputStream!ubyte sIn;
        if ("Transfer-Encoding" in headers && toLower(headers["Transfer-Encoding"][0]) == "chunked") {
            sIn = inputStreamObjectFor(chunkedEncodingInputStreamFor(inputStream));
        } else {
            sIn = inputStream;
        }
        ulong bytesRead = 0;
        ubyte[8192] buffer;
        while (contentLength == -1 || bytesRead < contentLength) {
            const ulong bytesToRead = (contentLength == -1)
                ? buffer.length
                : min(contentLength - bytesRead, buffer.length);
            StreamResult readResult = sIn.readFromStream(buffer[0 .. bytesToRead]);
            if (readResult.hasError) {
                return readResult;
            }
            if (readResult.count == 0) break;

            StreamResult writeResult = outputStream.writeToStream(buffer[0 .. readResult.count]);
            if (writeResult.hasError) {
                return writeResult;
            }
            if (writeResult.count  != readResult.count) {
                return StreamResult(StreamError("Failed to write all bytes that were read to the output stream.", 1));
            }
            bytesRead += writeResult.count;
        }
        // If a content-length was provided, but we didn't read as many bytes as specified, return an error.
        if (contentLength > 0 && bytesRead < contentLength) {
            return StreamResult(StreamError("Failed to read body according to provided Content-Length.", 1));
        }

        return StreamResult(cast(uint) bytesRead);
    }

    /**
     * Reads the request's body into a new byte array.
     * Params:
     *   allowInfiniteRead = Whether to allow reading even without a valid
     *                       Content-Length header.
     * Returns: The byte array.
     */
    ubyte[] readBodyAsBytes(bool allowInfiniteRead = false) {
        auto sOut = byteArrayOutputStream();
        StreamResult r = readBody(sOut, allowInfiniteRead);
        if (r.hasError) throw new Exception(cast(string) r.error.message);
        return sOut.toArray();
    }

    /**
     * Reads the request's body into a new string.
     * Params:
     *   allowInfiniteRead = Whether to allow reading even without a valid
     *                       Content-Length header.
     * Returns: The string content.
     */
    string readBodyAsString(bool allowInfiniteRead = false) {
        return cast(string) readBodyAsBytes(allowInfiniteRead);
    }
}

// Test getHeaderAs
unittest {
    InputStream!ubyte noOpInputStream = inputStreamObjectFor(arrayInputStreamFor!ubyte([]));
    ServerHttpRequest r1 = ServerHttpRequest(
        HttpVersion.V1,
        ClientAddress.unknown,
        HttpMethod.GET,
        "/test",
        ["Content-Type": ["application/json"], "Test": ["123", "456"]],
        [],
        noOpInputStream
    );
    assert(r1.getHeaderAs!string("Content-Type") == "application/json");
    assert(r1.getHeaderAs!string("content-type") == ""); // Case sensitivity.
    assert(r1.getHeaderAs!int("Content-Type") == 0);
    assert(r1.getHeaderAs!int("Test") == 123); // Check that we get the first header value.
    assert(r1.getHeaderAs!string("Test") == "123");
}

// Test readBody
unittest {
    ServerHttpRequest makeSampleRequest(S)(string[][string] headers, S inputStream) if (isByteInputStream!S) {
        return ServerHttpRequest(
            HttpVersion.V1,
            ClientAddress.unknown,
            HttpMethod.POST,
            "/test",
            headers,
            [],
            inputStreamObjectFor(inputStream)
        );
    }

    auto sOut = byteArrayOutputStream();

    // Base scenario with provided content length and correct values.
    auto r1 = makeSampleRequest(["Content-Length": ["5"]], arrayInputStreamFor!ubyte([1, 2, 3, 4, 5]));
    StreamResult result1 = r1.readBody(sOut, false);
    assert(result1.hasCount);
    assert(result1.count == 5);
    assert(sOut.toArray() == [1, 2, 3, 4, 5]);
    sOut.reset();

    // If content length is missing, and we don't allow infinite read, don't read anything.
    auto r2 = makeSampleRequest(["test": ["blah"]], arrayInputStreamFor!ubyte([1, 2, 3]));
    StreamResult result2 = r2.readBody(sOut, false);
    assert(result2.hasCount);
    assert(result2.count == 0);
    assert(sOut.toArray() == []);
    sOut.reset();

    // If content length is provided but is smaller than actual data, only read up to content length.
    auto r3 = makeSampleRequest(["Content-Length": ["3"]], arrayInputStreamFor!ubyte([1, 2, 3, 4, 5]));
    StreamResult result3 = r3.readBody(sOut, false);
    assert(result3.hasCount);
    assert(result3.count == 3);
    assert(sOut.toArray() == [1, 2, 3]);
    sOut.reset();

    // If content length is provided but larger than actual data, a stream error should be returned.
    auto r4 = makeSampleRequest(["Content-Length": ["8"]], arrayInputStreamFor!ubyte([1, 2, 3, 4, 5]));
    StreamResult result4 = r4.readBody(sOut, false);
    assert(result4.hasError);
    assert(result4.error.code == 1);
    assert(sOut.toArray().length == 5); // We should have read as much as we can from the request.
    sOut.reset();

    // If content length is not provided and we allow infinite read, read all body data.
    auto r5 = makeSampleRequest(["test": ["blah"]], arrayInputStreamFor!ubyte([1, 2, 3, 4, 5]));
    StreamResult result5 = r5.readBody(sOut, true);
    assert(result5.hasCount);
    assert(result5.count == 5);
    assert(sOut.toArray() == [1, 2, 3, 4, 5]);
    sOut.reset();

    // If content length is provided, and we allow infinite read, respect the declared content length and only read that many bytes.
    auto r6 = makeSampleRequest(["Content-Length": ["3"]], arrayInputStreamFor!ubyte([1, 2, 3, 4, 5]));
    StreamResult result6 = r6.readBody(sOut, true);
    assert(result6.hasCount);
    assert(result6.count == 3);
    assert(sOut.toArray() == [1, 2, 3]);
    sOut.reset();

    // Chunked-encoded data test: Write some chunked-encoded data to a buffer, and check that we can read it.
    auto chunkedTestBytesOut = byteArrayOutputStream();
    auto chunkedTestChunkedStream = ChunkedEncodingOutputStream!(ArrayOutputStream!ubyte*)(&chunkedTestBytesOut);
    chunkedTestChunkedStream.writeToStream([1, 2]);
    chunkedTestChunkedStream.writeToStream([3, 4, 5]);
    chunkedTestChunkedStream.writeToStream([6, 7, 8]);
    chunkedTestChunkedStream.writeToStream([9, 10]);
    chunkedTestChunkedStream.closeStream();
    ubyte[] chunkedData = chunkedTestBytesOut.toArray();

    auto r7 = makeSampleRequest(
        ["Content-Length": ["10"], "Transfer-Encoding": ["chunked"]],
        arrayInputStreamFor(chunkedData)
    );
    StreamResult result7 = r7.readBody(sOut, false);
    assert(result7.hasCount);
    assert(result7.count == 10);
    assert(sOut.toArray() == [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
    sOut.reset();
}

/**
 * Enumeration of all possible HTTP request versions.
 */
public enum HttpVersion : ubyte {
    /// HTTP Version 1, including versions 0.9, 1.0, and 1.1.
    V1      = 1 << 1,
    /// HTTP Version 2.
    V2      = 1 << 2,
    /// HTTP Version 3.
    V3      = 1 << 3
}

/** 
 * Enumeration of all possible HTTP methods, excluding extensions like WebDAV.
 * 
 * https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods
 */
public enum HttpMethod : string {
    GET     = "GET",
    HEAD    = "HEAD",
    POST    = "POST",
    PUT     = "PUT",
    DELETE  = "DELETE",
    CONNECT = "CONNECT",
    OPTIONS = "OPTIONS",
    TRACE   = "TRACE",
    PATCH   = "PATCH"
}

/// Stores a single query parameter's key and values.
struct QueryParameter {
    string key;
    string[] values;
}

/**
 * Parses a list of query parameters from a URL.
 * Params:
 *   url = The URL to parse query parameters from.
 * Returns: The list of query parameters.
 */
QueryParameter[] parseQueryParameters(string url) {
    if (url is null || url.length == 0) {
        return [];
    }
    ptrdiff_t paramsStartIdx = url.indexOf('?');
    if (paramsStartIdx == -1 || paramsStartIdx + 1 >= url.length) return [];

    string paramsStr = url[paramsStartIdx + 1 .. $];
    QueryParameter[] params;
    import std.array : RefAppender, appender; // TODO: Get rid of stdlib usage of std.array!
    RefAppender!(QueryParameter[]) app = appender(&params);
    size_t idx = 0;
    while (idx < paramsStr.length) {
        // First, isolate the text up to the next '&' separator.
        ptrdiff_t nextParamIdx = paramsStr.indexOf('&', idx);
        size_t currentParamEndIdx = nextParamIdx == -1 ? paramsStr.length : nextParamIdx;
        string currentParamStr = paramsStr[idx .. currentParamEndIdx];
        // Then, look for an '=' to separate the parameter's key and value.
        ptrdiff_t currentParamEqualsIdx = currentParamStr.indexOf('=');
        string key;
        string val;
        if (currentParamEqualsIdx == -1) {
            // No '=' is present, so we have a key with an empty value.
            key = currentParamStr;
            val = "";
        } else if (currentParamEqualsIdx == 0) {
            // The '=' is the first character, so the key is empty.
            key = "";
            val = currentParamStr[1 .. $];
        } else {
            // There is a legitimate key and value.
            key = currentParamStr[0 .. currentParamEqualsIdx];
            val = currentParamStr[currentParamEqualsIdx + 1 .. $];
        }
        // Clean up URI-encoded characters.
        // TODO: Do this without using std lib GC methods?
        import std.uri : decodeComponent;
        import std.string : replace;
        key = key.replace("+", " ").decodeComponent();
        val = val.replace("+", " ").decodeComponent();

        // If the key already exists, insert the value into that array.
        bool keyExists = false;
        foreach (ref param; params) {
            if (param.key == key) {
                param.values ~= val;
                keyExists = true;
                break;
            }
        }
        // Otherwise, add a new query parameter.
        if (!keyExists) {
            app ~= QueryParameter(key, [val]);
        }
        // Advance our current index pointer to the start of the next query parameter.
        // (past the '&' character separating query parameters)
        idx = currentParamEndIdx + 1;
    }

    return params;
}

unittest {
    QueryParameter[] r;
    // Test a basic common example.
    r = parseQueryParameters("https://www.example.com?a=1&b=2&c=3");
    assert(r == [QueryParameter("a", ["1"]), QueryParameter("b", ["2"]), QueryParameter("c", ["3"])]);
    // Test parsing multiple values for a single key.
    r = parseQueryParameters("test?key=a&key=b&key=abc");
    assert(r == [QueryParameter("key", ["a", "b", "abc"])]);
    // Test URLs without any parameters.
    assert(parseQueryParameters("test").length == 0);
    assert(parseQueryParameters("test?").length == 0);
    // Test parameter with any values.
    assert(parseQueryParameters("test?test") == [QueryParameter("test", [""])]);
    // Test parameter without a name.
    assert(parseQueryParameters("test?=value") == [QueryParameter("", ["value"])]);
    // Test URI-encoded parameter value.
    assert(parseQueryParameters(
        "test?key=this%20is%20a%20long%20sentence%21%28test%29") ==
        [QueryParameter("key", ["this is a long sentence!(test)"])]
    );
}

/**
 * Internal helper function to get the first index of a character in a string.
 * Params:
 *   s = The string to look in.
 *   c = The character to look for.
 *   offset = An optional offset to look from.
 * Returns: The index of the character, or -1.
 */
private ptrdiff_t indexOf(string s, char c, size_t offset = 0) {
    for (size_t i = offset; i < s.length; i++) {
        if (s[i] == c) return i;
    }
    return -1;
}

unittest {
    assert(indexOf("test", 't', 0) == 0);
    assert(indexOf("test", 't', 1) == 3);
    assert(indexOf("", 't', 0) == -1);
    assert(indexOf("test", 't', 100) == -1);
    assert(indexOf("test", 'a', 0) == -1);
}
