/**
 * Defines builder types to more easily construct various HTTP objects, often
 * useful for testing scenarios.
 */
module handy_http_primitives.builder;

import streams;

import handy_http_primitives.request;
import handy_http_primitives.response;
import handy_http_primitives.address;
import handy_http_primitives.multivalue_map;

/**
 * Fluent interface for building ServerHttpRequest objects.
 */
struct ServerHttpRequestBuilder {
    HttpVersion httpVersion = HttpVersion.V1;
    ClientAddress clientAddress = ClientAddress.unknown;
    string method = HttpMethod.GET;
    string url = "";
    string[][string] headers;
    QueryParameter[] queryParams;
    InputStream!ubyte inputStream = inputStreamObjectFor(NoOpInputStream!ubyte());
    Object[string] contextData;

    ref withVersion(HttpVersion httpVersion) {
        this.httpVersion = httpVersion;
        return this;
    }

    ref withClientAddress(ClientAddress addr) {
        this.clientAddress = addr;
        return this;
    }

    ref withMethod(string method) {
        this.method = method;
        return this;
    }

    ref withUrl(string url) {
        this.url = url;
        return this;
    }

    ref withHeader(string headerName, string value) {
        if (headerName !in this.headers) {
            this.headers[headerName] = [];
        }
        this.headers[headerName] ~= value;
        return this;
    }

    ref withQueryParam(string paramName, string value) {
        foreach (ref param; this.queryParams) {
            if (param.key == paramName) {
                param.values ~= value;
                return this;
            }
        }
        this.queryParams ~= QueryParameter(paramName, [value]);
        return this;
    }

    ref withInputStream(S)(S stream) if (isByteInputStream!S) {
        this.inputStream = inputStreamObjectFor(stream);
        return this;
    }

    ref withBody(ubyte[] bodyBytes) {
        return withInputStream(arrayInputStreamFor(bodyBytes));
    }

    ref withBody(string bodyStr) {
        return withBody(cast(ubyte[]) bodyStr);
    }

    ref withContextData(string key, Object obj) {
        this.contextData[key] = obj;
        return this;
    }

    ServerHttpRequest build() {
        return ServerHttpRequest(
            httpVersion,
            clientAddress,
            method,
            url,
            headers,
            queryParams,
            inputStream,
            contextData
        );
    }
}

unittest {
    class SampleContextData {
        string name;
        this(string name) {
            this.name = name;
        }
    }

    ServerHttpRequest r1 = ServerHttpRequestBuilder()
        .withUrl("/test-url")
        .withVersion(HttpVersion.V2)
        .withMethod(HttpMethod.PATCH)
        .withBody("Hello world!")
        .withClientAddress(ClientAddress.ofUnixSocket(UnixSocketAddress("/tmp/socket")))
        .withHeader("Content-Type", "text/plain")
        .withHeader("Content-Length", "12")
        .withQueryParam("idx", "42")
        .withContextData("name", new SampleContextData("andrew"))
        .build();
    assert(r1.httpVersion == HttpVersion.V2);
    assert(r1.url == "/test-url");
    assert(r1.method == HttpMethod.PATCH);
    string r1Body = r1.readBodyAsString();
    assert(r1Body == "Hello world!");
    assert(r1.clientAddress.type == ClientAddressType.UNIX);
    assert(r1.clientAddress.unixSocketAddress.path == "/tmp/socket");
    assert(r1.getHeaderAs!string("Content-Type") == "text/plain");
    assert(r1.getHeaderAs!ulong("Content-Length") == 12);
    assert(r1.getParamAs!ulong("idx") == 42);
    assert((cast(SampleContextData) r1.contextData["name"]).name == "andrew");
}

/**
 * Fluent interface for building ServerHttpResponse objects.
 */
struct ServerHttpResponseBuilder {
    StatusInfo initialStatus = HttpStatus.OK;
    StringMultiValueMap initialHeaders;
    OutputStream!ubyte outputStream = outputStreamObjectFor(NoOpOutputStream!ubyte());

    ref withStatus(StatusInfo status) {
        this.initialStatus = status;
        return this;
    }

    ref withHeader(string headerName, string value) {
        this.initialHeaders.add(headerName, value);
        return this;
    }

    ref withOutputStream(S)(S stream) if (isByteOutputStream!S) {
        this.outputStream = outputStreamObjectFor(stream);
        return this;
    }

    ServerHttpResponse build() {
        return ServerHttpResponse(
            initialStatus,
            initialHeaders,
            outputStream
        );
    }
}

unittest {
    ArrayOutputStream!ubyte bufferOut = byteArrayOutputStream();
    ServerHttpResponse r1 = ServerHttpResponseBuilder()
        .withStatus(HttpStatus.BAD_REQUEST)
        .withHeader("Test", "okay")
        .withOutputStream(&bufferOut)
        .build();
    
    assert(r1.status == HttpStatus.BAD_REQUEST);
    assert(r1.headers.getFirst("Test").value == "okay");
    r1.outputStream.writeToStream(cast(ubyte[]) "Hello world!");
    assert(bufferOut.toArray() == cast(ubyte[]) "Hello world!");
}
