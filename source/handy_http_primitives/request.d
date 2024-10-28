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
    /// The remote address of the client that sent this request.
    const InternetAddress clientAddress;
    /// The HTTP verb used in the request.
    const string method = HttpMethod.GET;
    /// The URL that was requested.
    const string url = "";
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
Optional!HttpMethod parseHttpMethod(S)(S s) if (isSomeString!S) {
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
    alias R = Optional!HttpMethod;
    assert(parseHttpMethod("GET") == R.of(HttpMethod.GET));
    assert(parseHttpMethod("get") == R.of(HttpMethod.GET));
    assert(parseHttpMethod("  geT ") == R.of(HttpMethod.GET));
    assert(parseHttpMethod("PATCH") == R.of(HttpMethod.PATCH));
    assert(parseHttpMethod(" not a method!") == R.empty);
    assert(parseHttpMethod("") == R.empty);
}

/// The data representing a remote IPv4 internet address, available as an int or bytes.
union IPv4InternetAddress {
    const uint intValue;
    const ubyte[4] bytes;
}

/// The data representing a remote IPv6 internet address.
struct IPv6InternetAddress {
    const ubyte[16] bytes;
}

/// A remote internet address, which is either IPv4 or IPv6. Check `isIPv6`.
struct InternetAddress {
    /// True if this address is IPv6. False if this is an IPv4 address.
    const bool isIPv6;
    /// The port number assigned to the connecting client on this machine.
    const ushort port;
    union {
        IPv4InternetAddress ipv4Address;
        IPv6InternetAddress ipv6Address;
    }
}
