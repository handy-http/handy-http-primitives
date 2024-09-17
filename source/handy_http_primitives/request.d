module handy_http_primitives.request;

import streams : InputStream;
import std.traits : isSomeString, EnumMembers;

import handy_http_primitives.multivalue_map;
import handy_http_primitives.optional;

/**
 * The HTTP request struct which represents the content of an HTTP request as
 * received by a server.
 */
struct ServerHttpRequest {
    /// The HTTP version of the request.
    const HttpVersion httpVersion = HttpVersion.V1_1;
    /// The HTTP verb used in the request.
    const HttpMethod method = HttpMethod.GET;
    /// The URL that was requested.
    const(char[]) url = "";
    /// A case-insensitive map of all request headers.
    const(CaseInsensitiveStringMultiValueMap) headers;
    /// A case-sensitive map of all URL query parameters.
    const(StringMultiValueMap) queryParams;
    /// The underlying stream used to read the body from the request.
    InputStream!ubyte inputStream;
}

/**
 * Enumeration of all possible HTTP request versions, as an unsigned byte for
 * efficient storage.
 */
public enum HttpVersion : ubyte {
    V1_1    = 1 << 1,
    V2      = 1 << 2,
    V3      = 1 << 3
}

/** 
 * Enumeration of all possible HTTP request methods as unsigned integer values
 * for efficient logic.
 * 
 * https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods
 */
public enum HttpMethod : ushort {
    GET     = 1 << 0,
    HEAD    = 1 << 1,
    POST    = 1 << 2,
    PUT     = 1 << 3,
    DELETE  = 1 << 4,
    CONNECT = 1 << 5,
    OPTIONS = 1 << 6,
    TRACE   = 1 << 7,
    PATCH   = 1 << 8
}

/**
 * Attempts to parse an HttpMethod from a string.
 * Params:
 *   s = The string to parse.
 * Returns: An optional which may contain an HttpMethod, if one was parsed.
 */
Optional!HttpMethod parseHttpMethod(S)(S s) if (isSomeString!S) {
    import std.uni : toUpper;
    import std.string : strip;
    import std.conv : to;
    static foreach (m; EnumMembers!HttpMethod) {
        if (s == to!string(m)) return Optional!HttpMethod.of(m);
    }
    const cleanStr = strip(toUpper(s));
    static foreach (m; EnumMembers!HttpMethod) {
        if (cleanStr == to!string(m)) return Optional!HttpMethod.of(m);
    }
    return Optional!HttpMethod.empty;
}

unittest {
    alias R = Optional!HttpMethod;
    assert(parseHttpMethod("GET") == R.of(HttpMethod.GET));
    assert(parseHttpMethod("get") == R.of(HttpMethod.GET));
    assert(parseHttpMethod("  geT ") == R.of(HttpMethod.GET));
    assert(parseHttpMethod("PATCH") == R.of(HttpMethod.PATCH));
    assert(parseHttpMethod(" not a method!") == R.empty);
    assert(parseHttpMethod("") == R.empty);
}
