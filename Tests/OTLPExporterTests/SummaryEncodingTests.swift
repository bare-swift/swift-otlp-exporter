// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import OTLPExporter
import Bytes

@Suite("ValueAtQuantile encoding")
struct ValueAtQuantileTests {
    @Test("empty (q=0.0, v=0.0) encodes to empty (both default-omitted)")
    func empty() {
        let bytes = EncodeMetrics.encodeValueAtQuantile(OTLP.ValueAtQuantile())
        #expect(Array(bytes.storage) == [])
    }

    @Test("quantile=0.5, value=1.0")
    func half() {
        var v = OTLP.ValueAtQuantile()
        v.quantile = 0.5
        v.value = 1.0
        let bytes = EncodeMetrics.encodeValueAtQuantile(v)
        var expected: [UInt8] = []
        expected.append(contentsOf: [0x09, 0, 0, 0, 0, 0, 0, 0xE0, 0x3F])
        expected.append(contentsOf: [0x11, 0, 0, 0, 0, 0, 0, 0xF0, 0x3F])
        #expect(Array(bytes.storage) == expected)
    }
}

@Suite("SummaryDataPoint encoding")
struct SummaryDataPointTests {
    @Test("empty SummaryDataPoint")
    func empty() {
        let bytes = EncodeMetrics.encodeSummaryDataPoint(OTLP.SummaryDataPoint())
        #expect(Array(bytes.storage) == [])
    }

    @Test("count=1, sum=2.0, one quantile_value (q=0.5, v=1.0)")
    func oneQuantile() {
        var dp = OTLP.SummaryDataPoint()
        dp.count = 1
        dp.sum = 2.0
        dp.quantileValues = [OTLP.ValueAtQuantile(quantile: 0.5, value: 1.0)]
        let bytes = EncodeMetrics.encodeSummaryDataPoint(dp)
        var expected: [UInt8] = []
        expected.append(contentsOf: [0x21, 0x01, 0, 0, 0, 0, 0, 0, 0])
        expected.append(contentsOf: [0x29, 0, 0, 0, 0, 0, 0, 0x00, 0x40])
        expected.append(contentsOf: [0x32, 0x12])
        expected.append(contentsOf: [0x09, 0, 0, 0, 0, 0, 0, 0xE0, 0x3F])
        expected.append(contentsOf: [0x11, 0, 0, 0, 0, 0, 0, 0xF0, 0x3F])
        #expect(Array(bytes.storage) == expected)
    }
}

@Suite("Summary encoding")
struct SummaryEncodingTests {
    @Test("empty Summary")
    func empty() {
        let bytes = EncodeMetrics.encodeSummary(OTLP.Summary())
        #expect(Array(bytes.storage) == [])
    }
}
