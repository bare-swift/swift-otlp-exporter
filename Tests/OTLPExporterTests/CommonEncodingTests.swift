// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import OTLPExporter
import Bytes

@Suite("AnyValue encoding")
struct AnyValueEncodingTests {
    @Test("string \"v\" encodes as field 1 (LEN)")
    func string() {
        let bytes = Encoder.encodeAnyValue(.string("v"))
        #expect(Array(bytes.storage) == [0x0A, 0x01, 0x76])
    }

    @Test("string \"\" still emits field 1 with empty length (presence semantics in oneof)")
    func emptyString() {
        let bytes = Encoder.encodeAnyValue(.string(""))
        #expect(Array(bytes.storage) == [0x0A, 0x00])
    }

    @Test("bool true encodes as field 2")
    func boolTrue() {
        let bytes = Encoder.encodeAnyValue(.bool(true))
        #expect(Array(bytes.storage) == [0x10, 0x01])
    }

    @Test("bool false in oneof still emits field 2 (presence)")
    func boolFalse() {
        let bytes = Encoder.encodeAnyValue(.bool(false))
        #expect(Array(bytes.storage) == [0x10, 0x00])
    }

    @Test("int 0 in oneof still emits field 3 (presence)")
    func intZero() {
        let bytes = Encoder.encodeAnyValue(.int(0))
        #expect(Array(bytes.storage) == [0x18, 0x00])
    }

    @Test("int 1 encodes as field 3")
    func intOne() {
        let bytes = Encoder.encodeAnyValue(.int(1))
        #expect(Array(bytes.storage) == [0x18, 0x01])
    }

    @Test("double 1.0 encodes as field 4")
    func doubleOne() {
        let bytes = Encoder.encodeAnyValue(.double(1.0))
        #expect(Array(bytes.storage) == [0x21, 0, 0, 0, 0, 0, 0, 0xF0, 0x3F])
    }

    @Test("bytes [0xAB] encodes as field 7")
    func bytesField() {
        let bytes = Encoder.encodeAnyValue(.bytes(Bytes([0xAB])))
        #expect(Array(bytes.storage) == [0x3A, 0x01, 0xAB])
    }

    @Test("array [int(1)] encodes as field 5 (LEN message of one AnyValue)")
    func arrayOfInt() {
        let bytes = Encoder.encodeAnyValue(.array([.int(1)]))
        #expect(Array(bytes.storage) == [0x2A, 0x04, 0x0A, 0x02, 0x18, 0x01])
    }

    @Test("kvlist [(k,string(v))] encodes as field 6")
    func kvlist() {
        let bytes = Encoder.encodeAnyValue(.kvlist([
            OTLP.KeyValue(key: "k", value: .string("v"))
        ]))
        let expected: [UInt8] = [
            0x32, 0x0A,
            0x0A, 0x08,
            0x0A, 0x01, 0x6B,
            0x12, 0x03, 0x0A, 0x01, 0x76,
        ]
        #expect(Array(bytes.storage) == expected)
    }
}

@Suite("KeyValue encoding")
struct KeyValueEncodingTests {
    @Test("KeyValue(key: \"k\", value: .string(\"v\"))")
    func basicKeyValue() {
        let bytes = Encoder.encodeKeyValue(OTLP.KeyValue(key: "k", value: .string("v")))
        #expect(Array(bytes.storage) == [
            0x0A, 0x01, 0x6B,
            0x12, 0x03, 0x0A, 0x01, 0x76,
        ])
    }
}

@Suite("Resource encoding")
struct ResourceEncodingTests {
    @Test("empty Resource encodes to empty bytes (all fields default)")
    func empty() {
        let bytes = Encoder.encodeResource(OTLP.Resource())
        #expect(Array(bytes.storage) == [])
    }

    @Test("Resource with one attribute KeyValue(\"k\", string(\"v\"))")
    func oneAttribute() {
        let res = OTLP.Resource(attributes: [
            OTLP.KeyValue(key: "k", value: .string("v"))
        ])
        let bytes = Encoder.encodeResource(res)
        #expect(Array(bytes.storage) == [
            0x0A, 0x08,
            0x0A, 0x01, 0x6B,
            0x12, 0x03, 0x0A, 0x01, 0x76,
        ])
    }

    @Test("Resource with dropped_attributes_count = 7")
    func droppedCount() {
        var res = OTLP.Resource()
        res.droppedAttributesCount = 7
        let bytes = Encoder.encodeResource(res)
        #expect(Array(bytes.storage) == [0x10, 0x07])
    }
}

@Suite("InstrumentationScope encoding")
struct InstrumentationScopeEncodingTests {
    @Test("empty scope encodes to empty bytes")
    func empty() {
        let bytes = Encoder.encodeInstrumentationScope(OTLP.InstrumentationScope())
        #expect(Array(bytes.storage) == [])
    }

    @Test("scope with name=\"x\", version=\"\"")
    func nameOnly() {
        let s = OTLP.InstrumentationScope(name: "x")
        let bytes = Encoder.encodeInstrumentationScope(s)
        #expect(Array(bytes.storage) == [0x0A, 0x01, 0x78])
    }

    @Test("scope with name=\"x\", version=\"1\"")
    func nameAndVersion() {
        let s = OTLP.InstrumentationScope(name: "x", version: "1")
        let bytes = Encoder.encodeInstrumentationScope(s)
        #expect(Array(bytes.storage) == [0x0A, 0x01, 0x78, 0x12, 0x01, 0x31])
    }
}
