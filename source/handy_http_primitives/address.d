/**
 * Defines various address types for use with HTTP communication.
 */
module handy_http_primitives.address;

/**
 * Represents a 4-byte IPv4 network address and the port number on this machine
 * that the connection was assigned to.
 */
struct IPv4InternetAddress {
    const ubyte[4] bytes;
    const ushort port;
}

/**
 * Represents a 16-byte IPv6 network address and the port number on this
 * machine that the connection was assigned to.
 */
struct IPv6InternetAddress {
    const ubyte[16] bytes;
    const ushort port;
}

/**
 * Represents a unix socket address, which is just a path to a file at which
 * IO operations take place.
 */
struct UnixSocketAddress {
    const string path;
}

/// Defines the different possible address types, used by `ClientAddress`.
enum ClientAddressType {
    IPv4,
    IPv6,
    UNIX,
    UNKNOWN
}

/**
 * A compound type representing the address of any entity sending an HTTP
 * request. Use `type` to determine which information is available.
 */
struct ClientAddress {
    const ClientAddressType type;
    const IPv4InternetAddress ipv4InternetAddress;
    const IPv6InternetAddress ipv6InternetAddress;
    const UnixSocketAddress unixSocketAddress;

    /**
     * Serializes this address in a human-readable string representation.
     * Returns: The string representation of this address.
     */
    string toString() const {
        if (type == ClientAddressType.UNKNOWN) return "Unknown Address";
        if (type == ClientAddressType.UNIX) return unixSocketAddress.path;
        version (Posix) { import core.sys.posix.arpa.inet : inet_ntop, AF_INET, AF_INET6; }
        version (Windows) { import core.sys.windows.winsock2 : inet_ntop, AF_INET, AF_INET6; }
        const int addressFamily = type == ClientAddressType.IPv4
            ? AF_INET
            :AF_INET6;
        const scope void* inputBytes = type == ClientAddressType.IPv4
            ? ipv4InternetAddress.bytes.ptr
            : ipv6InternetAddress.bytes.ptr;
        const ushort port = type == ClientAddressType.IPv4
            ? ipv4InternetAddress.port
            : ipv6InternetAddress.port;
        char[45] buf; // Buffer is sized to maximum possible IPv6 length (39 chars), plus 6 chars for port string.
        auto ret = inet_ntop(addressFamily, inputBytes, buf.ptr, buf.length);
        if (ret is null) {
            throw new Exception("Failed to serialize address.");
        }
        size_t strLength = 0;
        while (buf[strLength] != '\0') strLength++;
        buf[strLength++] = ':';
        writeUIntToBuffer(port, buf, strLength);
        return buf[0..strLength].idup;
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

    static ClientAddress unknown() {
        return ClientAddress(
            ClientAddressType.UNKNOWN,
            IPv4InternetAddress.init,
            IPv6InternetAddress.init,
            UnixSocketAddress.init
        );
    }
}

unittest {
    ClientAddress addr = ClientAddress.ofIPv4(IPv4InternetAddress([127, 0, 0, 1], 8000));
    assert(addr.toString == "127.0.0.1:8000");
    ClientAddress addr6 = ClientAddress.ofIPv6(IPv6InternetAddress(
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        8000
    ));
    assert(addr6.toString == ":::8000");
    // TODO: Add more comprehensive testing.
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
