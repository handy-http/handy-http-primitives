module handy_http_primitives.handler;

import handy_http_primitives.request;
import handy_http_primitives.response;

/**
 * Defines the request handler interface, which is called upon to handle an
 * incoming HTTP request.
 */
interface HttpRequestHandler {
    void handle(ref ServerHttpRequest request, ref ServerHttpResponse response);
}
