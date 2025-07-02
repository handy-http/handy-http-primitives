/**
 * Defines the HTTP response structure and associated types that are generally
 * used when formulating a response to a client's request.
 */
module handy_http_primitives.response;

import streams : OutputStream;

import handy_http_primitives.multivalue_map;

/**
 * The response that's sent by a server back to a client after processing the
 * client's HTTP request.
 */
struct ServerHttpResponse {
    /// The response status.
    StatusInfo status = HttpStatus.OK;
    /// A multi-valued map containing all headers.
    StringMultiValueMap headers;
    /// The stream to which the response body is written.
    OutputStream!ubyte outputStream;
    
    /**
     * Writes an array of bytes to the response's output stream.
     * Params:
     *   bytes = The bytes to write.
     *   contentType = The declared content type of the data, which is written
     *                 as the "Content-Type" header.
     */
    void writeBodyBytes(ubyte[] bytes, string contentType = ContentTypes.APPLICATION_OCTET_STREAM) {
        import std.conv : to;
        headers.add("Content-Type", contentType);
        headers.add("Content-Length", to!string(bytes.length));
        // We trust that when we write to the output stream, the transport
        // implementation will handle properly formatting the headers and other
        // HTTP boilerplate response content prior to actually writing the body.
        auto result = outputStream.writeToStream(bytes);
        if (result.hasError) {
            throw new Exception(
                "Failed to write bytes to the response's output stream: " ~
                cast(string) result.error.message
            );
        }
    }

    /**
     * Writes a string of content to the response's output stream.
     * Params:
     *   content = The content to write.
     *   contentType = The declared content type of the data, which is written
     *                 as the "Content-Type" header.
     */
    void writeBodyString(string content, string contentType = ContentTypes.TEXT_PLAIN) {
        writeBodyBytes(cast(ubyte[]) content, contentType);
    }
}

/** 
 * A struct containing basic information about a response status.
 */
struct StatusInfo {
    ushort code;
    string text;
}

/** 
 * An enum defining all valid HTTP response statuses:
 * See here: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
 */
enum HttpStatus : StatusInfo {
    // Information
    CONTINUE                        = StatusInfo(100, "Continue"),
    SWITCHING_PROTOCOLS             = StatusInfo(101, "Switching Protocols"),
    PROCESSING                      = StatusInfo(102, "Processing"),
    EARLY_HINTS                     = StatusInfo(103, "Early Hints"),

    // Success
    OK                              = StatusInfo(200, "OK"),
    CREATED                         = StatusInfo(201, "Created"),
    ACCEPTED                        = StatusInfo(202, "Accepted"),
    NON_AUTHORITATIVE_INFORMATION   = StatusInfo(203, "Non-Authoritative Information"),
    NO_CONTENT                      = StatusInfo(204, "No Content"),
    RESET_CONTENT                   = StatusInfo(205, "Reset Content"),
    PARTIAL_CONTENT                 = StatusInfo(206, "Partial Content"),
    MULTI_STATUS                    = StatusInfo(207, "Multi-Status"),
    ALREADY_REPORTED                = StatusInfo(208, "Already Reported"),
    IM_USED                         = StatusInfo(226, "IM Used"),

    // Redirection
    MULTIPLE_CHOICES                = StatusInfo(300, "Multiple Choices"),
    MOVED_PERMANENTLY               = StatusInfo(301, "Moved Permanently"),
    FOUND                           = StatusInfo(302, "Found"),
    SEE_OTHER                       = StatusInfo(303, "See Other"),
    NOT_MODIFIED                    = StatusInfo(304, "Not Modified"),
    TEMPORARY_REDIRECT              = StatusInfo(307, "Temporary Redirect"),
    PERMANENT_REDIRECT              = StatusInfo(308, "Permanent Redirect"),

    // Client error
    BAD_REQUEST                     = StatusInfo(400, "Bad Request"),
    UNAUTHORIZED                    = StatusInfo(401, "Unauthorized"),
    PAYMENT_REQUIRED                = StatusInfo(402, "Payment Required"),
    FORBIDDEN                       = StatusInfo(403, "Forbidden"),
    NOT_FOUND                       = StatusInfo(404, "Not Found"),
    METHOD_NOT_ALLOWED              = StatusInfo(405, "Method Not Allowed"),
    NOT_ACCEPTABLE                  = StatusInfo(406, "Not Acceptable"),
    PROXY_AUTHENTICATION_REQUIRED   = StatusInfo(407, "Proxy Authentication Required"),
    REQUEST_TIMEOUT                 = StatusInfo(408, "Request Timeout"),
    CONFLICT                        = StatusInfo(409, "Conflict"),
    GONE                            = StatusInfo(410, "Gone"),
    LENGTH_REQUIRED                 = StatusInfo(411, "Length Required"),
    PRECONDITION_FAILED             = StatusInfo(412, "Precondition Failed"),
    PAYLOAD_TOO_LARGE               = StatusInfo(413, "Payload Too Large"),
    URI_TOO_LONG                    = StatusInfo(414, "URI Too Long"),
    UNSUPPORTED_MEDIA_TYPE          = StatusInfo(415, "Unsupported Media Type"),
    RANGE_NOT_SATISFIABLE           = StatusInfo(416, "Range Not Satisfiable"),
    EXPECTATION_FAILED              = StatusInfo(417, "Expectation Failed"),
    IM_A_TEAPOT                     = StatusInfo(418, "I'm a teapot"),
    MISDIRECTED_REQUEST             = StatusInfo(421, "Misdirected Request"),
    UNPROCESSABLE_CONTENT           = StatusInfo(422, "Unprocessable Content"),
    LOCKED                          = StatusInfo(423, "Locked"),
    FAILED_DEPENDENCY               = StatusInfo(424, "Failed Dependency"),
    TOO_EARLY                       = StatusInfo(425, "Too Early"),
    UPGRADE_REQUIRED                = StatusInfo(426, "Upgrade Required"),
    PRECONDITION_REQUIRED           = StatusInfo(428, "Precondition Required"),
    TOO_MANY_REQUESTS               = StatusInfo(429, "Too Many Requests"),
    REQUEST_HEADER_FIELDS_TOO_LARGE = StatusInfo(431, "Request Header Fields Too Large"),
    UNAVAILABLE_FOR_LEGAL_REASONS   = StatusInfo(451, "Unavailable For Legal Reasons"),

    // Server error
    INTERNAL_SERVER_ERROR           = StatusInfo(500, "Internal Server Error"),
    NOT_IMPLEMENTED                 = StatusInfo(501, "Not Implemented"),
    BAD_GATEWAY                     = StatusInfo(502, "Bad Gateway"),
    SERVICE_UNAVAILABLE             = StatusInfo(503, "Service Unavailable"),
    GATEWAY_TIMEOUT                 = StatusInfo(504, "Gateway Timeout"),
    HTTP_VERSION_NOT_SUPPORTED      = StatusInfo(505, "HTTP Version Not Supported"),
    VARIANT_ALSO_NEGOTIATES         = StatusInfo(506, "Variant Also Negotiates"),
    INSUFFICIENT_STORAGE            = StatusInfo(507, "Insufficient Storage"),
    LOOP_DETECTED                   = StatusInfo(508, "Loop Detected"),
    NOT_EXTENDED                    = StatusInfo(510, "Not Extended"),
    NETWORK_AUTHENTICATION_REQUIRED = StatusInfo(511, "Network Authentication Required")
}

/// Common "Content-Type" header values.
enum ContentTypes : string {
    APPLICATION_JSON                = "application/json",
    APPLICATION_XML                 = "application/xml",
    APPLICATION_OCTET_STREAM        = "application/octet-stream",
    APPLICATION_PDF                 = "application/pdf",

    TEXT_PLAIN                      = "text/plain",
    TEXT_HTML                       = "text/html",
    TEXT_CSS                        = "text/css",
    TEXT_CSV                        = "text/csv",
    TEXT_JAVASCRIPT                 = "text/javascript",
    TEXT_MARKDOWN                   = "text/markdown",

    IMAGE_JPEG                      = "image/jpeg",
    IMAGE_PNG                       = "image/png",
    IMAGE_SVG                       = "image/svg+xml"
}

/**
 * An exception that can be thrown while handling an HTTP request, to indicate
 * that the server should return a specified response code, usually when you
 * want to short-circuit due to an error.
 */
class HttpStatusException : Exception {
    const StatusInfo status;

    this(StatusInfo status, string message, Throwable next) {
        super(message, next);
        this.status = status;
    }

    this(StatusInfo status, string message) {
        this(status, message, null);
    }

    this(StatusInfo status) {
        this(status, "An error occurred while processing the request.", null);
    }
}
