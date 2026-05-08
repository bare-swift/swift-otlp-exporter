// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import OTLPExporter
import Bytes

@Suite("ProtoWriter — wire-format primitives")
struct ProtoWriterTests {

    // MARK: - Varint

    @Test("writeVarint of 0, 1, 127, 128, 16383, 16384, UInt64.max")
    func writeVarintBoundaries() {
        var w = ProtoWriter()
        w.writeVarint(0)
        #expect(Array(w.finish().storage) == [0x00])

        var w1 = ProtoWriter(); w1.writeVarint(1)
        #expect(Array(w1.finish().storage) == [0x01])

        var w127 = ProtoWriter(); w127.writeVarint(127)
        #expect(Array(w127.finish().storage) == [0x7F])

        var w128 = ProtoWriter(); w128.writeVarint(128)
        #expect(Array(w128.finish().storage) == [0x80, 0x01])

        var w300 = ProtoWriter(); w300.writeVarint(300)
        #expect(Array(w300.finish().storage) == [0xAC, 0x02])

        var w16383 = ProtoWriter(); w16383.writeVarint(16383)
        #expect(Array(w16383.finish().storage) == [0xFF, 0x7F])

        var w16384 = ProtoWriter(); w16384.writeVarint(16384)
        #expect(Array(w16384.finish().storage) == [0x80, 0x80, 0x01])

        var wMax = ProtoWriter(); wMax.writeVarint(UInt64.max)
        #expect(Array(wMax.finish().storage) == [
            0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x01,
        ])
    }

    // MARK: - I32 / I64 (little-endian)

    @Test("writeI32 little-endian")
    func writeI32LE() {
        var w = ProtoWriter()
        w.writeI32(0x01020304)
        #expect(Array(w.finish().storage) == [0x04, 0x03, 0x02, 0x01])
    }

    @Test("writeI64 little-endian")
    func writeI64LE() {
        var w = ProtoWriter()
        w.writeI64(0x0102030405060708)
        #expect(Array(w.finish().storage) == [0x08, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01])
    }

    @Test("double 1.0 round-trips through writeI64(bitPattern)")
    func writeDouble1_0() {
        var w = ProtoWriter()
        w.writeI64(Double(1.0).bitPattern)
        #expect(Array(w.finish().storage) == [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0x3F])
    }

    @Test("double 2.0")
    func writeDouble2_0() {
        var w = ProtoWriter()
        w.writeI64(Double(2.0).bitPattern)
        #expect(Array(w.finish().storage) == [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x40])
    }

    @Test("double -1.0")
    func writeDoubleNeg1() {
        var w = ProtoWriter()
        w.writeI64(Double(-1.0).bitPattern)
        #expect(Array(w.finish().storage) == [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xF0, 0xBF])
    }

    // MARK: - Tag

    @Test("writeTag for field=1 wire=VARINT yields 0x08")
    func tagField1Varint() {
        var w = ProtoWriter()
        w.writeTag(field: 1, wireType: .varint)
        #expect(Array(w.finish().storage) == [0x08])
    }

    @Test("writeTag for field=1 wire=LEN yields 0x0A")
    func tagField1Len() {
        var w = ProtoWriter()
        w.writeTag(field: 1, wireType: .len)
        #expect(Array(w.finish().storage) == [0x0A])
    }

    @Test("writeTag for field=15 wire=LEN yields 0x7A (single-byte boundary)")
    func tagField15() {
        var w = ProtoWriter()
        w.writeTag(field: 15, wireType: .len)
        #expect(Array(w.finish().storage) == [0x7A])
    }

    @Test("writeTag for field=16 wire=LEN crosses varint boundary")
    func tagField16() {
        var w = ProtoWriter()
        w.writeTag(field: 16, wireType: .len)
        #expect(Array(w.finish().storage) == [0x82, 0x01])
    }

    // MARK: - Length-delimited

    @Test("writeLengthDelimited prepends varint length")
    func writeLenDelim() {
        var w = ProtoWriter()
        w.writeLengthDelimited(Bytes([0x68, 0x69]))
        #expect(Array(w.finish().storage) == [0x02, 0x68, 0x69])
    }

    @Test("writeLengthDelimited of empty Bytes is just 0x00")
    func writeLenDelimEmpty() {
        var w = ProtoWriter()
        w.writeLengthDelimited(Bytes())
        #expect(Array(w.finish().storage) == [0x00])
    }

    // MARK: - Composition

    @Test("writeTag(1, LEN) + writeLengthDelimited(\"hi\") = full string-1 wire form")
    func tagPlusLenDelim() {
        var w = ProtoWriter()
        w.writeTag(field: 1, wireType: .len)
        w.writeLengthDelimited(Bytes([0x68, 0x69]))
        #expect(Array(w.finish().storage) == [0x0A, 0x02, 0x68, 0x69])
    }
}

@Suite("ProtoWriter — field helpers")
struct ProtoWriterFieldHelperTests {

    // MARK: - Scalar with proto3 default omission

    @Test("writeUInt64(_:fieldNumber:) emits tag+varint when non-zero")
    func uint64NonZero() {
        var w = ProtoWriter()
        w.writeUInt64(42, fieldNumber: 1)
        #expect(Array(w.finish().storage) == [0x08, 0x2A])
    }

    @Test("writeUInt64(_:fieldNumber:) omits when value is 0")
    func uint64Zero() {
        var w = ProtoWriter()
        w.writeUInt64(0, fieldNumber: 1)
        #expect(Array(w.finish().storage) == [])
    }

    @Test("writeUInt32(_:fieldNumber:) omits when 0; emits when non-zero")
    func uint32() {
        var w = ProtoWriter()
        w.writeUInt32(0, fieldNumber: 4)
        #expect(Array(w.finish().storage) == [])

        var w2 = ProtoWriter()
        w2.writeUInt32(7, fieldNumber: 4)
        #expect(Array(w2.finish().storage) == [0x20, 0x07])
    }

    @Test("writeBool(_:fieldNumber:) omits when false; emits 0x__ 0x01 when true")
    func bool() {
        var w = ProtoWriter()
        w.writeBool(false, fieldNumber: 3)
        #expect(Array(w.finish().storage) == [])

        var w2 = ProtoWriter()
        w2.writeBool(true, fieldNumber: 3)
        #expect(Array(w2.finish().storage) == [0x18, 0x01])
    }

    @Test("writeString(_:fieldNumber:) omits when empty; emits tag+len+bytes when non-empty")
    func string() {
        var w = ProtoWriter()
        w.writeString("", fieldNumber: 1)
        #expect(Array(w.finish().storage) == [])

        var w2 = ProtoWriter()
        w2.writeString("hi", fieldNumber: 1)
        #expect(Array(w2.finish().storage) == [0x0A, 0x02, 0x68, 0x69])
    }

    @Test("writeBytes(_:fieldNumber:) omits when empty; emits tag+len+bytes when non-empty")
    func bytesField() {
        var w = ProtoWriter()
        w.writeBytes(Bytes(), fieldNumber: 7)
        #expect(Array(w.finish().storage) == [])

        var w2 = ProtoWriter()
        w2.writeBytes(Bytes([0xAB, 0xCD]), fieldNumber: 7)
        #expect(Array(w2.finish().storage) == [0x3A, 0x02, 0xAB, 0xCD])
    }

    @Test("writeMessage(_:fieldNumber:) emits tag+len+bytes; empty message still emits tag+0 (caller decides whether to call)")
    func message() {
        var w = ProtoWriter()
        w.writeMessage(Bytes([0x08, 0x01]), fieldNumber: 2)
        #expect(Array(w.finish().storage) == [0x12, 0x02, 0x08, 0x01])
    }

    // MARK: - Fixed64 / fixed32 / double / float (with default omission)

    @Test("writeFixed64(_:fieldNumber:) omits when 0; emits tag + 8 LE bytes when non-zero")
    func fixed64() {
        var w = ProtoWriter()
        w.writeFixed64(0, fieldNumber: 2)
        #expect(Array(w.finish().storage) == [])

        var w2 = ProtoWriter()
        w2.writeFixed64(1, fieldNumber: 2)
        #expect(Array(w2.finish().storage) == [0x11, 0x01, 0, 0, 0, 0, 0, 0, 0])
    }

    @Test("writeDouble(_:fieldNumber:) omits when value is 0.0; emits when non-zero")
    func doubleField() {
        var w = ProtoWriter()
        w.writeDouble(0.0, fieldNumber: 1)
        #expect(Array(w.finish().storage) == [])

        var w2 = ProtoWriter()
        w2.writeDouble(1.0, fieldNumber: 1)
        #expect(Array(w2.finish().storage) == [0x09, 0, 0, 0, 0, 0, 0, 0xF0, 0x3F])
    }

    @Test("writeOptionalDouble(_:fieldNumber:) emits when .some, omits when nil — even for value=0")
    func optionalDouble() {
        var w = ProtoWriter()
        w.writeOptionalDouble(nil, fieldNumber: 5)
        #expect(Array(w.finish().storage) == [])

        var w2 = ProtoWriter()
        w2.writeOptionalDouble(0.0, fieldNumber: 5)
        #expect(Array(w2.finish().storage) == [0x29, 0, 0, 0, 0, 0, 0, 0, 0])

        var w3 = ProtoWriter()
        w3.writeOptionalDouble(1.0, fieldNumber: 5)
        #expect(Array(w3.finish().storage) == [0x29, 0, 0, 0, 0, 0, 0, 0xF0, 0x3F])
    }

    // MARK: - Enum

    @Test("writeEnum(_:fieldNumber:) treats 0 as default and omits; emits tag+varint otherwise")
    func enumField() {
        var w = ProtoWriter()
        w.writeEnum(0, fieldNumber: 2)
        #expect(Array(w.finish().storage) == [])

        var w2 = ProtoWriter()
        w2.writeEnum(2, fieldNumber: 2)
        #expect(Array(w2.finish().storage) == [0x10, 0x02])
    }

    // MARK: - SInt32 (ZigZag varint)

    @Test("writeSInt32 maps -1 → ZigZag 1, then varint")
    func sint32Negative1() {
        var w = ProtoWriter()
        w.writeSInt32(-1, fieldNumber: 1)
        #expect(Array(w.finish().storage) == [0x08, 0x01])
    }

    @Test("writeSInt32 maps 1 → ZigZag 2")
    func sint32Pos1() {
        var w = ProtoWriter()
        w.writeSInt32(1, fieldNumber: 1)
        #expect(Array(w.finish().storage) == [0x08, 0x02])
    }

    @Test("writeSInt32 omits when value is 0 (proto3 default)")
    func sint32Zero() {
        var w = ProtoWriter()
        w.writeSInt32(0, fieldNumber: 1)
        #expect(Array(w.finish().storage) == [])
    }

    // MARK: - Packed repeated

    @Test("writePackedUInt64 emits LEN-prefixed run of varints")
    func packedUInt64() {
        var w = ProtoWriter()
        w.writePackedUInt64([1, 2, 128], fieldNumber: 1)
        #expect(Array(w.finish().storage) == [0x0A, 0x04, 0x01, 0x02, 0x80, 0x01])
    }

    @Test("writePackedUInt64 omits when array is empty")
    func packedUInt64Empty() {
        var w = ProtoWriter()
        w.writePackedUInt64([], fieldNumber: 1)
        #expect(Array(w.finish().storage) == [])
    }

    @Test("writePackedFixed64 emits LEN-prefixed run of 8-byte little-endian values")
    func packedFixed64() {
        var w = ProtoWriter()
        w.writePackedFixed64([1, 2], fieldNumber: 6)
        var expected: [UInt8] = [0x32, 0x10]
        expected.append(contentsOf: [0x01, 0, 0, 0, 0, 0, 0, 0])
        expected.append(contentsOf: [0x02, 0, 0, 0, 0, 0, 0, 0])
        #expect(Array(w.finish().storage) == expected)
    }

    @Test("writePackedDouble emits LEN-prefixed run of doubles")
    func packedDouble() {
        var w = ProtoWriter()
        w.writePackedDouble([1.0, 2.0], fieldNumber: 7)
        var expected: [UInt8] = [0x3A, 0x10]
        expected.append(contentsOf: [0, 0, 0, 0, 0, 0, 0xF0, 0x3F])
        expected.append(contentsOf: [0, 0, 0, 0, 0, 0, 0x00, 0x40])
        #expect(Array(w.finish().storage) == expected)
    }
}
