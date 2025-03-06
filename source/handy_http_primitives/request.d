module handy_http_primitives.request;

import streams : InputStream;
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
    const ClientAddress clientAddress;
    /// The HTTP verb used in the request.
    const string method = HttpMethod.GET;
    /// The URL that was requested.
    const string url = "";
    /// A case-insensitive map of all request headers.
    const(string[][string]) headers;
    /// The underlying stream used to read the body from the request.
    InputStream!ubyte inputStream;
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

/**
 * Attempts to parse an HttpMethod from a string.
 * Params:
 *   s = The string to parse.
 * Returns: An optional which may contain an HttpMethod, if one was parsed.
 */
Optional!HttpMethod parseHttpMethod(string s) {
    // TODO: Remove this function now that we're using plain string HTTP methods.
    import std.uni : toUpper;
    import std.string : strip;
    static foreach (m; EnumMembers!HttpMethod) {
        if (s == m) return Optional!HttpMethod.of(m);
    }
    const cleanStr = strip(toUpper(s));
    static foreach (m; EnumMembers!HttpMethod) {
        if (cleanStr == m) return Optional!HttpMethod.of(m);
    }
    return Optional!HttpMethod.empty;
}

unittest {
    assert(parseHttpMethod("GET") == Optional!HttpMethod.of(HttpMethod.GET));
    assert(parseHttpMethod("get") == Optional!HttpMethod.of(HttpMethod.GET));
    assert(parseHttpMethod("  geT ") == Optional!HttpMethod.of(HttpMethod.GET));
    assert(parseHttpMethod("PATCH") == Optional!HttpMethod.of(HttpMethod.PATCH));
    assert(parseHttpMethod(" not a method!") == Optional!HttpMethod.empty);
    assert(parseHttpMethod("") == Optional!HttpMethod.empty);
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
            params ~= QueryParameter(key, [val]);
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
