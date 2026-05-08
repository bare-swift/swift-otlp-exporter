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

    // MARK: - Field helpers (proto3 default omission)

    /// `uint64` field. Omitted when value is 0 (proto3 default).
    mutating func writeUInt64(_ value: UInt64, fieldNumber: UInt32) {
        guard value != 0 else { return }
        writeTag(field: fieldNumber, wireType: .varint)
        writeVarint(value)
    }

    /// `uint32` field. Omitted when value is 0 (proto3 default).
    mutating func writeUInt32(_ value: UInt32, fieldNumber: UInt32) {
        guard value != 0 else { return }
        writeTag(field: fieldNumber, wireType: .varint)
        writeVarint(UInt64(value))
    }

    /// `bool` field. Omitted when false (proto3 default).
    mutating func writeBool(_ value: Bool, fieldNumber: UInt32) {
        guard value else { return }
        writeTag(field: fieldNumber, wireType: .varint)
        writeVarint(1)
    }

    /// `string` field. Omitted when empty (proto3 default).
    mutating func writeString(_ value: String, fieldNumber: UInt32) {
        guard !value.isEmpty else { return }
        writeTag(field: fieldNumber, wireType: .len)
        let utf8Bytes = Bytes(value.utf8)
        writeLengthDelimited(utf8Bytes)
    }

    /// `bytes` field. Omitted when empty (proto3 default).
    mutating func writeBytes(_ value: Bytes, fieldNumber: UInt32) {
        guard !value.isEmpty else { return }
        writeTag(field: fieldNumber, wireType: .len)
        writeLengthDelimited(value)
    }

    /// Embedded `message` field. Caller has already encoded the inner message.
    /// Always emits tag+length, even for an empty payload (caller decides whether to call).
    mutating func writeMessage(_ payload: Bytes, fieldNumber: UInt32) {
        writeTag(field: fieldNumber, wireType: .len)
        writeLengthDelimited(payload)
    }

    /// `fixed64` field. Omitted when value is 0 (proto3 default).
    mutating func writeFixed64(_ value: UInt64, fieldNumber: UInt32) {
        guard value != 0 else { return }
        writeTag(field: fieldNumber, wireType: .i64)
        writeI64(value)
    }

    /// `fixed32` field. Omitted when value is 0 (proto3 default).
    mutating func writeFixed32(_ value: UInt32, fieldNumber: UInt32) {
        guard value != 0 else { return }
        writeTag(field: fieldNumber, wireType: .i32)
        writeI32(value)
    }

    /// `double` field. Omitted when value is exactly +0.0 (proto3 default).
    /// NaN, +Inf, -Inf, and -0.0 are all encoded.
    mutating func writeDouble(_ value: Double, fieldNumber: UInt32) {
        if value == 0.0 && value.sign == .plus { return }
        writeTag(field: fieldNumber, wireType: .i64)
        writeI64(value.bitPattern)
    }

    /// `optional double` field (proto3 explicit-presence). Emits when `.some`,
    /// even when value is 0.0; omits when `nil`.
    mutating func writeOptionalDouble(_ value: Double?, fieldNumber: UInt32) {
        guard let value = value else { return }
        writeTag(field: fieldNumber, wireType: .i64)
        writeI64(value.bitPattern)
    }

    /// `enum` field. Omitted when value is 0 (proto3 default — typically the
    /// `_UNSPECIFIED` enumerator).
    mutating func writeEnum(_ value: UInt32, fieldNumber: UInt32) {
        guard value != 0 else { return }
        writeTag(field: fieldNumber, wireType: .varint)
        writeVarint(UInt64(value))
    }

    /// `sint32` field. ZigZag-encoded then varint. Omitted when value is 0.
    mutating func writeSInt32(_ value: Int32, fieldNumber: UInt32) {
        guard value != 0 else { return }
        let zz: UInt32 = Varint.ZigZag.encode(value)
        writeTag(field: fieldNumber, wireType: .varint)
        writeVarint(UInt64(zz))
    }

    // MARK: - Packed repeated

    /// Packed `repeated uint64`. Omitted when array is empty.
    mutating func writePackedUInt64(_ values: [UInt64], fieldNumber: UInt32) {
        guard !values.isEmpty else { return }
        var inner = ProtoWriter()
        for v in values { inner.writeVarint(v) }
        let innerBytes = inner.finish()
        writeTag(field: fieldNumber, wireType: .len)
        writeLengthDelimited(innerBytes)
    }

    /// Packed `repeated fixed64`. Omitted when array is empty.
    mutating func writePackedFixed64(_ values: [UInt64], fieldNumber: UInt32) {
        guard !values.isEmpty else { return }
        var inner = ProtoWriter()
        for v in values { inner.writeI64(v) }
        let innerBytes = inner.finish()
        writeTag(field: fieldNumber, wireType: .len)
        writeLengthDelimited(innerBytes)
    }

    /// Packed `repeated double`. Omitted when array is empty.
    mutating func writePackedDouble(_ values: [Double], fieldNumber: UInt32) {
        guard !values.isEmpty else { return }
        var inner = ProtoWriter()
        for v in values { inner.writeI64(v.bitPattern) }
        let innerBytes = inner.finish()
        writeTag(field: fieldNumber, wireType: .len)
        writeLengthDelimited(innerBytes)
    }
}
