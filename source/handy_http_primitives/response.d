module handy_http_primitives.response;

import streams;

import handy_http_primitives.multivalue_map;

struct HttpResponse {
    StatusInfo status = HttpStatus.OK;
    StringMultiValueMap headers;
    OutputStream!ubyte outputStream;
}

/** 
 * A struct containing basic information about a response status.
 */
struct StatusInfo {
    const ushort code;
    const string text;
}

/** 
 * An enum defining all valid HTTP response statuses:
 * See here: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
 */
enum HttpStatus : StatusInfo {
    // Information
    CONTINUE = StatusInfo(100, "Continue"),
    SWITCHING_PROTOCOLS = StatusInfo(101, "Switching Protocols"),
    PROCESSING = StatusInfo(102, "Processing"),
    EARLY_HINTS = StatusInfo(103, "Early Hints"),

    // Success
    OK = StatusInfo(200, "OK"),
    CREATED = StatusInfo(201, "Created"),
    ACCEPTED = StatusInfo(202, "Accepted"),
    NON_AUTHORITATIVE_INFORMATION = StatusInfo(203, "Non-Authoritative Information"),
    NO_CONTENT = StatusInfo(204, "No Content"),
    RESET_CONTENT = StatusInfo(205, "Reset Content"),
    PARTIAL_CONTENT = StatusInfo(206, "Partial Content"),
    MULTI_STATUS = StatusInfo(207, "Multi-Status"),
    ALREADY_REPORTED = StatusInfo(208, "Already Reported"),
    IM_USED = StatusInfo(226, "IM Used"),

    // Redirection
    MULTIPLE_CHOICES = StatusInfo(300, "Multiple Choices"),
    MOVED_PERMANENTLY = StatusInfo(301, "Moved Permanently"),
    FOUND = StatusInfo(302, "Found"),
    SEE_OTHER = StatusInfo(303, "See Other"),
    NOT_MODIFIED = StatusInfo(304, "Not Modified"),
    TEMPORARY_REDIRECT = StatusInfo(307, "Temporary Redirect"),
    PERMANENT_REDIRECT = StatusInfo(308, "Permanent Redirect"),

    // Client error
    BAD_REQUEST = StatusInfo(400, "Bad Request"),
    UNAUTHORIZED = StatusInfo(401, "Unauthorized"),
    PAYMENT_REQUIRED = StatusInfo(402, "Payment Required"),
    FORBIDDEN = StatusInfo(403, "Forbidden"),
    NOT_FOUND = StatusInfo(404, "Not Found"),
    METHOD_NOT_ALLOWED = StatusInfo(405, "Method Not Allowed"),
    NOT_ACCEPTABLE = StatusInfo(406, "Not Acceptable"),
    PROXY_AUTHENTICATION_REQUIRED = StatusInfo(407, "Proxy Authentication Required"),
    REQUEST_TIMEOUT = StatusInfo(408, "Request Timeout"),
    CONFLICT = StatusInfo(409, "Conflict"),
    GONE = StatusInfo(410, "Gone"),
    LENGTH_REQUIRED = StatusInfo(411, "Length Required"),
    PRECONDITION_FAILED = StatusInfo(412, "Precondition Failed"),
    PAYLOAD_TOO_LARGE = StatusInfo(413, "Payload Too Large"),
    URI_TOO_LONG = StatusInfo(414, "URI Too Long"),
    UNSUPPORTED_MEDIA_TYPE = StatusInfo(415, "Unsupported Media Type"),
    RANGE_NOT_SATISFIABLE = StatusInfo(416, "Range Not Satisfiable"),
    EXPECTATION_FAILED = StatusInfo(417, "Expectation Failed"),
    IM_A_TEAPOT = StatusInfo(418, "I'm a teapot"),
    MISDIRECTED_REQUEST = StatusInfo(421, "Misdirected Request"),
    UNPROCESSABLE_CONTENT = StatusInfo(422, "Unprocessable Content"),
    LOCKED = StatusInfo(423, "Locked"),
    FAILED_DEPENDENCY = StatusInfo(424, "Failed Dependency"),
    TOO_EARLY = StatusInfo(425, "Too Early"),
    UPGRADE_REQUIRED = StatusInfo(426, "Upgrade Required"),
    PRECONDITION_REQUIRED = StatusInfo(428, "Precondition Required"),
    TOO_MANY_REQUESTS = StatusInfo(429, "Too Many Requests"),
    REQUEST_HEADER_FIELDS_TOO_LARGE = StatusInfo(431, "Request Header Fields Too Large"),
    UNAVAILABLE_FOR_LEGAL_REASONS = StatusInfo(451, "Unavailable For Legal Reasons"),

    // Server error
    INTERNAL_SERVER_ERROR = StatusInfo(500, "Internal Server Error"),
    NOT_IMPLEMENTED = StatusInfo(501, "Not Implemented"),
    BAD_GATEWAY = StatusInfo(502, "Bad Gateway"),
    SERVICE_UNAVAILABLE = StatusInfo(503, "Service Unavailable"),
    GATEWAY_TIMEOUT = StatusInfo(504, "Gateway Timeout"),
    HTTP_VERSION_NOT_SUPPORTED = StatusInfo(505, "HTTP Version Not Supported"),
    VARIANT_ALSO_NEGOTIATES = StatusInfo(506, "Variant Also Negotiates"),
    INSUFFICIENT_STORAGE = StatusInfo(507, "Insufficient Storage"),
    LOOP_DETECTED = StatusInfo(508, "Loop Detected"),
    NOT_EXTENDED = StatusInfo(510, "Not Extended"),
    NETWORK_AUTHENTICATION_REQUIRED = StatusInfo(511, "Network Authentication Required")
}
