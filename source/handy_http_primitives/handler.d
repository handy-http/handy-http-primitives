module handy_http_primitives.handler;

import handy_http_primitives.request;
import handy_http_primitives.response;

interface HttpRequestHandler {
    void handle(in HttpRequest request, ref HttpResponse response);
}