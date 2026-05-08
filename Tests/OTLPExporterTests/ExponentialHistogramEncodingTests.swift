// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import OTLPExporter
import Bytes

@Suite("Buckets encoding")
struct BucketsEncodingTests {
    @Test("empty Buckets")
    func empty() {
        let bytes = EncodeMetrics.encodeBuckets(OTLP.Buckets())
        #expect(Array(bytes.storage) == [])
    }

    @Test("offset=-1 (ZigZag) only")
    func offsetNeg1() {
        var b = OTLP.Buckets(); b.offset = -1
        let bytes = EncodeMetrics.encodeBuckets(b)
        #expect(Array(bytes.storage) == [0x08, 0x01])
    }

    @Test("bucketCounts=[1, 2] packed at field 2")
    func bucketCounts() {
        var b = OTLP.Buckets(); b.bucketCounts = [1, 2]
        let bytes = EncodeMetrics.encodeBuckets(b)
        #expect(Array(bytes.storage) == [0x12, 0x02, 0x01, 0x02])
    }
}

@Suite("ExponentialHistogramDataPoint encoding")
struct ExpoHistDataPointTests {
    @Test("empty data point")
    func empty() {
        let bytes = EncodeMetrics.encodeExponentialHistogramDataPoint(
            OTLP.ExponentialHistogramDataPoint()
        )
        #expect(Array(bytes.storage) == [])
    }

    @Test("scale=2 (positive sint32) only")
    func scalePos2() {
        var dp = OTLP.ExponentialHistogramDataPoint()
        dp.scale = 2
        let bytes = EncodeMetrics.encodeExponentialHistogramDataPoint(dp)
        #expect(Array(bytes.storage) == [0x30, 0x04])
    }

    @Test("count=1, sum=2.0 (NOT optional in expo histo), zeroCount=0, no buckets, no scale")
    func basic() {
        var dp = OTLP.ExponentialHistogramDataPoint()
        dp.count = 1
        dp.sum = 2.0
        let bytes = EncodeMetrics.encodeExponentialHistogramDataPoint(dp)
        var expected: [UInt8] = []
        expected.append(contentsOf: [0x21, 0x01, 0, 0, 0, 0, 0, 0, 0])
        expected.append(contentsOf: [0x29, 0, 0, 0, 0, 0, 0, 0x00, 0x40])
        #expect(Array(bytes.storage) == expected)
    }
}

@Suite("ExponentialHistogram encoding")
struct ExpoHistEncodingTests {
    @Test("empty ExponentialHistogram")
    func empty() {
        let bytes = EncodeMetrics.encodeExponentialHistogram(OTLP.ExponentialHistogram())
        #expect(Array(bytes.storage) == [])
    }

    @Test("delta temporality only")
    func temporality() {
        let h = OTLP.ExponentialHistogram(aggregationTemporality: .delta)
        let bytes = EncodeMetrics.encodeExponentialHistogram(h)
        #expect(Array(bytes.storage) == [0x10, 0x01])
    }
}
