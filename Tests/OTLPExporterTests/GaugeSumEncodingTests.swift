// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import OTLPExporter
import Bytes

@Suite("Gauge encoding")
struct GaugeEncodingTests {
    @Test("empty Gauge encodes to empty")
    func empty() {
        let bytes = EncodeMetrics.encodeGauge(OTLP.Gauge())
        #expect(Array(bytes.storage) == [])
    }

    @Test("Gauge with one NumberDataPoint{ value=.asInt(1) }")
    func oneInt() {
        var dp = OTLP.NumberDataPoint(); dp.value = .asInt(1)
        let g = OTLP.Gauge(dataPoints: [dp])
        let bytes = EncodeMetrics.encodeGauge(g)
        #expect(Array(bytes.storage) == [
            0x0A, 0x09,
            0x31, 0x01, 0, 0, 0, 0, 0, 0, 0,
        ])
    }
}

@Suite("Sum encoding")
struct SumEncodingTests {
    @Test("empty Sum encodes to empty")
    func empty() {
        let bytes = EncodeMetrics.encodeSum(OTLP.Sum())
        #expect(Array(bytes.storage) == [])
    }

    @Test("Sum with aggregationTemporality=.cumulative, isMonotonic=true, no data points")
    func temporalityAndMonotonic() {
        let s = OTLP.Sum(
            dataPoints: [],
            aggregationTemporality: .cumulative,
            isMonotonic: true
        )
        let bytes = EncodeMetrics.encodeSum(s)
        #expect(Array(bytes.storage) == [0x10, 0x02, 0x18, 0x01])
    }

    @Test("Sum with delta temporality and no monotonic flag")
    func deltaTemporality() {
        let s = OTLP.Sum(
            aggregationTemporality: .delta,
            isMonotonic: false
        )
        let bytes = EncodeMetrics.encodeSum(s)
        #expect(Array(bytes.storage) == [0x10, 0x01])
    }
}
