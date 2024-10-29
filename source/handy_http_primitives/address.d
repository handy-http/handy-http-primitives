/**
 * Defines various address types for use with HTTP communication.
 */
module handy_http_primitives.address;

struct IPv4InternetAddress {
    const ubyte[4] bytes;
    const ushort port;

    string toString() const {
        char[21] buffer;
        size_t idx;
        for (size_t i = 0; i < 4; i++) {
            writeUIntToBuffer(bytes[i], buffer, idx);
            if (i < 3) buffer[idx++] = '.';
        }
        buffer[idx++] = ':';
        writeUIntToBuffer(port, buffer, idx);
        return buffer[0 .. idx].idup;
    }
}

struct IPv6InternetAddress {
    const ubyte[16] bytes;
    const ushort port;

    string toString() const {
        return "Not implemented!";
    }
}

struct UnixSocketAddress {
    const string path;

    string toString() const {
        return path;
    }
}

enum ClientAddressType {
    IPv4,
    IPv6,
    UNIX
}

struct ClientAddress {
    const ClientAddressType type;
    const IPv4InternetAddress ipv4InternetAddress;
    const IPv6InternetAddress ipv6InternetAddress;
    const UnixSocketAddress unixSocketAddress;

    string toString() const {
        if (type == ClientAddressType.IPv4) {
            return ipv4InternetAddress.toString();
        } else if (type == ClientAddressType.IPv6) {
            return ipv6InternetAddress.toString();
        } else {
            return unixSocketAddress.toString();
        }
    }

    static ClientAddress ofIPv4(IPv4InternetAddress addr) {
        return ClientAddress(ClientAddressType.IPv4, addr, IPv6InternetAddress.init, UnixSocketAddress.init);
    }

    static ClientAddress ofIPv6(IPv6InternetAddress addr) {
        return ClientAddress(ClientAddressType.IPv6, IPv4InternetAddress.init, addr, UnixSocketAddress.init);
    }

    static ClientAddress ofUnixSocket(UnixSocketAddress addr) {
        return ClientAddress(ClientAddressType.UNIX, IPv4InternetAddress.init, IPv6InternetAddress.init, addr);
    }
}

unittest {
    ClientAddress addr = ClientAddress.ofIPv4(IPv4InternetAddress([127, 0, 0, 1], 8000));
    assert(addr.toString == "127.0.0.1:8000");
}

/**
 * Helper function to append an unsigned integer value to a char buffer. It is
 * assumed that there's enough space to write value.
 * Params:
 *   value = The value to append.
 *   buffer = The buffer to append to.
 *   idx = A reference to a variable tracking the next writable index in the buffer.
 */
private void writeUIntToBuffer(uint value, char[] buffer, ref size_t idx) {
    const size_t startIdx = idx;
    while (true) {
        ubyte remainder = value % 10;
        value /= 10;
        buffer[idx++] = cast(char) ('0' + remainder);
        if (value == 0) break;
    }
    // Swap the characters to proper order.
    for (size_t i = 0; i < (idx - startIdx) / 2; i++) {
        size_t p1 = i + startIdx;
        size_t p2 = idx - i - 1;
        char tmp = buffer[p1];
        buffer[p1] = buffer[p2];
        buffer[p2] = tmp;
    }
}
