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
