// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import OTLPExporter
import Bytes

@Suite("AggregationTemporality")
struct AggregationTemporalityTests {
    @Test("rawValue mapping: unspecified=0, delta=1, cumulative=2")
    func rawValues() {
        #expect(OTLP.AggregationTemporality.unspecified.rawValue == 0)
        #expect(OTLP.AggregationTemporality.delta.rawValue == 1)
        #expect(OTLP.AggregationTemporality.cumulative.rawValue == 2)
    }
}

@Suite("Exemplar encoding")
struct ExemplarEncodingTests {
    @Test("empty Exemplar encodes to empty (all fields default)")
    func empty() {
        let bytes = EncodeMetrics.encodeExemplar(OTLP.Exemplar())
        #expect(Array(bytes.storage) == [])
    }

    @Test("Exemplar.value=.asInt(1) encodes as sfixed64 at field 6")
    func asInt() {
        var e = OTLP.Exemplar()
        e.value = .asInt(1)
        let bytes = EncodeMetrics.encodeExemplar(e)
        #expect(Array(bytes.storage) == [0x31, 0x01, 0, 0, 0, 0, 0, 0, 0])
    }

    @Test("Exemplar.value=.asDouble(1.0) encodes as double at field 3")
    func asDouble() {
        var e = OTLP.Exemplar()
        e.value = .asDouble(1.0)
        let bytes = EncodeMetrics.encodeExemplar(e)
        #expect(Array(bytes.storage) == [0x19, 0, 0, 0, 0, 0, 0, 0xF0, 0x3F])
    }

    @Test("Exemplar with timeUnixNano=1 only")
    func timeOnly() {
        var e = OTLP.Exemplar()
        e.timeUnixNano = 1
        let bytes = EncodeMetrics.encodeExemplar(e)
        #expect(Array(bytes.storage) == [0x11, 0x01, 0, 0, 0, 0, 0, 0, 0])
    }
}

@Suite("NumberDataPoint encoding")
struct NumberDataPointEncodingTests {
    @Test("empty NumberDataPoint encodes to empty")
    func empty() {
        let bytes = EncodeMetrics.encodeNumberDataPoint(OTLP.NumberDataPoint())
        #expect(Array(bytes.storage) == [])
    }

    @Test("NumberDataPoint with as_int=42")
    func asInt42() {
        var p = OTLP.NumberDataPoint()
        p.value = .asInt(42)
        let bytes = EncodeMetrics.encodeNumberDataPoint(p)
        #expect(Array(bytes.storage) == [0x31, 0x2A, 0, 0, 0, 0, 0, 0, 0])
    }

    @Test("NumberDataPoint with timeUnixNano=1, as_double=1.0")
    func timeAndDouble() {
        var p = OTLP.NumberDataPoint()
        p.timeUnixNano = 1
        p.value = .asDouble(1.0)
        let bytes = EncodeMetrics.encodeNumberDataPoint(p)
        #expect(Array(bytes.storage) == [
            0x19, 0x01, 0, 0, 0, 0, 0, 0, 0,
            0x21, 0, 0, 0, 0, 0, 0, 0xF0, 0x3F,
        ])
    }

    @Test("NumberDataPoint with one attribute KeyValue(\"k\", string(\"v\")), value=.asInt(1)")
    func withAttribute() {
        var p = OTLP.NumberDataPoint()
        p.attributes = [OTLP.KeyValue(key: "k", value: .string("v"))]
        p.value = .asInt(1)
        let bytes = EncodeMetrics.encodeNumberDataPoint(p)
        var expected: [UInt8] = []
        expected.append(contentsOf: [0x31, 0x01, 0, 0, 0, 0, 0, 0, 0])
        expected.append(contentsOf: [0x3A, 0x08, 0x0A, 0x01, 0x6B, 0x12, 0x03, 0x0A, 0x01, 0x76])
        #expect(Array(bytes.storage) == expected)
    }
}
