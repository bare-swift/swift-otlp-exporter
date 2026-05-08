// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import OTLPExporter
import Bytes

@Suite("HistogramDataPoint encoding")
struct HistogramDataPointEncodingTests {
    @Test("empty HistogramDataPoint")
    func empty() {
        let bytes = EncodeMetrics.encodeHistogramDataPoint(OTLP.HistogramDataPoint())
        #expect(Array(bytes.storage) == [])
    }

    @Test("count=1, sum=.some(2.5), bucketCounts=[1], bounds=[]")
    func basic() {
        var dp = OTLP.HistogramDataPoint()
        dp.count = 1
        dp.sum = 2.5
        dp.bucketCounts = [1]
        let bytes = EncodeMetrics.encodeHistogramDataPoint(dp)
        var expected: [UInt8] = []
        expected.append(contentsOf: [0x21, 0x01, 0, 0, 0, 0, 0, 0, 0])
        expected.append(contentsOf: [0x29, 0, 0, 0, 0, 0, 0, 0x04, 0x40])
        expected.append(contentsOf: [0x32, 0x08, 0x01, 0, 0, 0, 0, 0, 0, 0])
        #expect(Array(bytes.storage) == expected)
    }

    @Test("explicitBounds=[1.0, 2.0] packed at field 7")
    func explicitBounds() {
        var dp = OTLP.HistogramDataPoint()
        dp.explicitBounds = [1.0, 2.0]
        let bytes = EncodeMetrics.encodeHistogramDataPoint(dp)
        var expected: [UInt8] = [0x3A, 0x10]
        expected.append(contentsOf: [0, 0, 0, 0, 0, 0, 0xF0, 0x3F])
        expected.append(contentsOf: [0, 0, 0, 0, 0, 0, 0x00, 0x40])
        #expect(Array(bytes.storage) == expected)
    }

    @Test("min=.some(0.0), max=.some(10.0) — optional double presence")
    func minMax() {
        var dp = OTLP.HistogramDataPoint()
        dp.min = 0.0
        dp.max = 10.0
        let bytes = EncodeMetrics.encodeHistogramDataPoint(dp)
        var expected: [UInt8] = []
        expected.append(contentsOf: [0x59, 0, 0, 0, 0, 0, 0, 0, 0])
        expected.append(contentsOf: [0x61, 0, 0, 0, 0, 0, 0, 0x24, 0x40])
        #expect(Array(bytes.storage) == expected)
    }
}

@Suite("Histogram encoding")
struct HistogramEncodingTests {
    @Test("empty Histogram")
    func empty() {
        let bytes = EncodeMetrics.encodeHistogram(OTLP.Histogram())
        #expect(Array(bytes.storage) == [])
    }

    @Test("Histogram with cumulative temporality only")
    func temporality() {
        let h = OTLP.Histogram(aggregationTemporality: .cumulative)
        let bytes = EncodeMetrics.encodeHistogram(h)
        #expect(Array(bytes.storage) == [0x10, 0x02])
    }
}
