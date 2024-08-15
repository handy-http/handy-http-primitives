/**
 * Module that defines an `Optional` type, which is a simplified version of
 * Phobos' Nullable, that also supports mapping the underlying data.
 */
module handy_http_primitives.optional;

import std.typecons : Nullable;

/**
 * A simple wrapper around a value to make it optionally present.
 */
struct Optional(T) {
    /// The internal value of this optional.
    T value;

    /// Whether this optional is empty.
    bool isNull = true;

    /**
     * Constructs an optional value using a given value.
     * Params:
     *   value = The value to use.
     * Returns: An optional that contains the given value.
     */
    static Optional!T of(T value) {
        return Optional!T(value, false);
    }

    /**
     * Constructs an optional value using a Phobos nullable.
     * Params:
     *   nullableValue = The nullable value to use.
     * Returns: An optional that contains the given nullable value.
     */
    static Optional!T of (Nullable!T nullableValue) {
        if (nullableValue.isNull) return Optional!T.empty();
        return Optional!T.of(nullableValue.get);
    }

    /**
     * Constructs an optional that's empty.
     * Returns: An optional that is empty.
     */
    static Optional!T empty() {
        return Optional!T(T.init, true);
    }

    /**
     * Converts this optional to a Phobos-style Nullable.
     * Returns: A `Nullable!T` representing this optional.
     */
    Nullable!T asNullable() {
        Nullable!T n;
        if (!this.isNull) {
            n = this.value;
        }
        return n;
    }

    /**
     * Gets the value of this optional if it exists, otherwise uses a given
     * default value.
     * Params:
     *   defaultValue = The value to return if no default value exists.
     * Returns: The value of the optional, or the default value if this
     * optional is empty.
     */
    T orElse(T defaultValue) {
        if (this.isNull) return defaultValue;
        return this.value;
    }

    /**
     * Gets the value of this optional if it exists, or throws an exception.
     * Params:
     *   msg = A message to put in the exception.
     * Returns: The value of this optional.
     */
    T orElseThrow(string msg = "Optional value is null.") {
        if (this.isNull) throw new Exception(msg);
        return this.value;
    }

    /**
     * Gets the value of this optional if it exists, or throws an exception as
     * produced by the given delegate.
     * Params:
     *   exceptionSupplier = A delegate that returns an exception to throw if
     *                       this optional is null.
     * Returns: The value of this optional.
     */
    T orElseThrow(Exception delegate() exceptionSupplier) {
        if (this.isNull) throw exceptionSupplier();
        return this.value;
    }

    /**
     * Provides a mechanism to allow usage in boolean expressions.
     * Returns: true if non-null, false if null
     * ---
     * auto optInt = Optional!int.empty();
     * assert(!optInt);
     * auto optStr = Optional!string.of("Hello");
     * assert(optStr);
     * ---
     */
    bool opCast(B : bool)() const {
        return !this.isNull;
    }
}

/**
 * Maps the value of a given optional to another type using a given function.
 * Params:
 *   opt = The optional to map.
 * Returns: An optional whose type is the return-type of the given `fn`
 * template argument function.
 */
auto mapIfPresent(alias fn, T)(Optional!T opt) {
    alias U = typeof(fn(T.init));
    if (opt.isNull) return Optional!U.empty();
    return Optional!U.of(fn(opt.value));
}

unittest {
    Optional!string s = Optional!string.of("hello");
    assert(!s.isNull);
    assert(s.value == "hello");
    assert(s); // test boolean conversion
    Optional!int mapped = s.mapIfPresent!(str => 1);
    assert(!mapped.isNull);
    assert(mapped.value == 1);
}
