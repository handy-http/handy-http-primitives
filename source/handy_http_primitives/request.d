module handy_http_primitives.request;

import streams;

import handy_http_primitives.multivalue_map;

struct HttpRequest {
    const ubyte httpVersion = 1;
    const Method method = Method.GET;
    const string url = "";
    const(CaseInsensitiveStringMultiValueMap) headers;
    const(StringMultiValueMap) queryParams;
    InputStream!ubyte inputStream;
}

/** 
 * Enumeration of all possible HTTP request methods as unsigned integer values
 * for efficient logic.
 * 
 * https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods
 */
public enum Method : ushort {
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
