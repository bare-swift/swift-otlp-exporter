// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes
import Varint

/// Internal protobuf wire-format writer. Bytes-backed; produces exact
/// proto3 wire format for the subset OTLP needs. Helpers for proto3
/// default-value omission and packed-repeated are added in Task 7.
struct ProtoWriter {
    /// Wire types used by OTLP. Group types (3, 4) are deprecated; not used.
    enum WireType: UInt32 {
        case varint = 0
        case i64    = 1
        case len    = 2
        case i32    = 5
    }

    private var bytes: Bytes

    init(reservingCapacity capacity: Int = 256) {
        self.bytes = Bytes(reservingCapacity: capacity)
    }

    consuming func finish() -> Bytes { bytes }

    /// Append a tag (field_number << 3 | wire_type), encoded as varint.
    mutating func writeTag(field: UInt32, wireType: WireType) {
        let tag: UInt64 = (UInt64(field) << 3) | UInt64(wireType.rawValue)
        writeVarint(tag)
    }

    /// Append a ULEB128-encoded unsigned varint.
    mutating func writeVarint(_ value: UInt64) {
        bytes.append(contentsOf: Varint.encode(value))
    }

    /// Append a 32-bit little-endian fixed value (for `fixed32`, `sfixed32`, `float`).
    mutating func writeI32(_ value: UInt32) {
        bytes.append(UInt8(truncatingIfNeeded: value))
        bytes.append(UInt8(truncatingIfNeeded: value >> 8))
        bytes.append(UInt8(truncatingIfNeeded: value >> 16))
        bytes.append(UInt8(truncatingIfNeeded: value >> 24))
    }

    /// Append a 64-bit little-endian fixed value (for `fixed64`, `sfixed64`, `double`).
    mutating func writeI64(_ value: UInt64) {
        bytes.append(UInt8(truncatingIfNeeded: value))
        bytes.append(UInt8(truncatingIfNeeded: value >> 8))
        bytes.append(UInt8(truncatingIfNeeded: value >> 16))
        bytes.append(UInt8(truncatingIfNeeded: value >> 24))
        bytes.append(UInt8(truncatingIfNeeded: value >> 32))
        bytes.append(UInt8(truncatingIfNeeded: value >> 40))
        bytes.append(UInt8(truncatingIfNeeded: value >> 48))
        bytes.append(UInt8(truncatingIfNeeded: value >> 56))
    }

    /// Append a length-delimited block: varint length, then the raw bytes.
    /// Used for strings, bytes, embedded messages, and packed-repeated.
    mutating func writeLengthDelimited(_ payload: Bytes) {
        writeVarint(UInt64(payload.count))
        bytes.append(contentsOf: payload.storage)
    }
}
