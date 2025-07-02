/**
 * Defines the core request handler interface that's the starting point for
 * all HTTP request processing.
 */
module handy_http_primitives.handler;

import handy_http_primitives.request;
import handy_http_primitives.response;

/**
 * Defines the request handler interface, which is called upon to handle an
 * incoming HTTP request.
 */
interface HttpRequestHandler {
    /**
     * Invoked to handle an incoming HTTP request. Implementations should read
     * information from the request, and write to the response.
     * Params:
     *   request = The request that was sent by a client.
     *   response = The response that will be sent back to the client.
     */
    void handle(ref ServerHttpRequest request, ref ServerHttpResponse response);

    /**
     * Gets a request handler that invokes the given function.
     * Params:
     *   fn = The function to invoke when handling requests.
     * Returns: The request handler.
     */
    static HttpRequestHandler of(void function(ref ServerHttpRequest, ref ServerHttpResponse) fn) {
        return new class HttpRequestHandler {
            override void handle(ref ServerHttpRequest request, ref ServerHttpResponse response) {
                fn(request, response);
            }
        };
    }

    /**
     * Gets a request handler that invokes the given delegate.
     * Params:
     *   dg = The delegate to invoke when handling requests.
     * Returns: The request handler.
     */
    static HttpRequestHandler of(void delegate(ref ServerHttpRequest, ref ServerHttpResponse) dg) {
        return new class HttpRequestHandler {
            override void handle(ref ServerHttpRequest request, ref ServerHttpResponse response) {
                dg(request, response);
            }
        };
    }
}
