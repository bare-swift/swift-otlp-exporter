// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import OTLPExporter
import Bytes

@Suite("Metric encoding (oneof data)")
struct MetricOneofTests {
    @Test("empty Metric encodes to empty bytes")
    func empty() {
        let bytes = EncodeMetrics.encodeMetric(OTLP.Metric())
        #expect(Array(bytes.storage) == [])
    }

    @Test("Metric with name=\"x\" only")
    func nameOnly() {
        let m = OTLP.Metric(name: "x")
        let bytes = EncodeMetrics.encodeMetric(m)
        #expect(Array(bytes.storage) == [0x0A, 0x01, 0x78])
    }

    @Test("Metric with name=\"x\" and gauge field 5 (no data points)")
    func emptyGauge() {
        let m = OTLP.Metric(name: "x", data: .gauge(OTLP.Gauge()))
        let bytes = EncodeMetrics.encodeMetric(m)
        #expect(Array(bytes.storage) == [0x0A, 0x01, 0x78, 0x2A, 0x00])
    }

    @Test("Metric with sum oneof at field 7")
    func sumDataField() {
        let m = OTLP.Metric(name: "x", data: .sum(OTLP.Sum()))
        let bytes = EncodeMetrics.encodeMetric(m)
        #expect(Array(bytes.storage) == [0x0A, 0x01, 0x78, 0x3A, 0x00])
    }
}

@Suite("ScopeMetrics encoding")
struct ScopeMetricsTests {
    @Test("empty ScopeMetrics")
    func empty() {
        let bytes = EncodeMetrics.encodeScopeMetrics(OTLP.ScopeMetrics())
        #expect(Array(bytes.storage) == [])
    }

    @Test("ScopeMetrics with scope.name=\"x\"")
    func withScope() {
        let sm = OTLP.ScopeMetrics(
            scope: OTLP.InstrumentationScope(name: "x")
        )
        let bytes = EncodeMetrics.encodeScopeMetrics(sm)
        #expect(Array(bytes.storage) == [0x0A, 0x03, 0x0A, 0x01, 0x78])
    }
}

@Suite("ResourceMetrics encoding")
struct ResourceMetricsTests {
    @Test("empty ResourceMetrics")
    func empty() {
        let bytes = EncodeMetrics.encodeResourceMetrics(OTLP.ResourceMetrics())
        #expect(Array(bytes.storage) == [])
    }
}

@Suite("OTLP.encode(_:) end-to-end")
struct OTLPEncodeEndToEndTests {
    @Test("empty ExportMetricsServiceRequest encodes to empty Bytes")
    func emptyRequest() {
        let req = OTLP.ExportMetricsServiceRequest()
        let payload = OTLP.encode(req)
        #expect(payload.isEmpty)
    }

    @Test("minimal request with one Resource → one Scope → one Metric{name=\"x\", gauge=empty}")
    func minimalRequest() {
        let req = OTLP.ExportMetricsServiceRequest(resourceMetrics: [
            OTLP.ResourceMetrics(
                resource: OTLP.Resource(),
                scopeMetrics: [
                    OTLP.ScopeMetrics(
                        scope: OTLP.InstrumentationScope(),
                        metrics: [
                            OTLP.Metric(name: "x", data: .gauge(OTLP.Gauge()))
                        ]
                    )
                ]
            )
        ])
        let payload = OTLP.encode(req)

        let metricInner: [UInt8] = [0x0A, 0x01, 0x78, 0x2A, 0x00]
        var scopeMetricsInner: [UInt8] = []
        scopeMetricsInner.append(contentsOf: [0x12, 0x05])
        scopeMetricsInner.append(contentsOf: metricInner)
        var resourceMetricsInner: [UInt8] = []
        resourceMetricsInner.append(contentsOf: [0x12, UInt8(scopeMetricsInner.count)])
        resourceMetricsInner.append(contentsOf: scopeMetricsInner)
        var expected: [UInt8] = []
        expected.append(contentsOf: [0x0A, UInt8(resourceMetricsInner.count)])
        expected.append(contentsOf: resourceMetricsInner)

        #expect(Array(payload.storage) == expected)
    }

    @Test("request with one counter (Sum + isMonotonic, one NumberDataPoint as_int=42)")
    func counterEndToEnd() {
        let req = OTLP.ExportMetricsServiceRequest(resourceMetrics: [
            OTLP.ResourceMetrics(
                resource: OTLP.Resource(attributes: [
                    OTLP.KeyValue(key: "k", value: .string("v"))
                ]),
                scopeMetrics: [
                    OTLP.ScopeMetrics(
                        scope: OTLP.InstrumentationScope(name: "s"),
                        metrics: [
                            OTLP.Metric(
                                name: "c",
                                data: .sum(OTLP.Sum(
                                    dataPoints: [
                                        {
                                            var dp = OTLP.NumberDataPoint()
                                            dp.value = .asInt(42)
                                            return dp
                                        }()
                                    ],
                                    aggregationTemporality: .cumulative,
                                    isMonotonic: true
                                ))
                            )
                        ]
                    )
                ]
            )
        ])
        let payload = OTLP.encode(req)

        let bs = Array(payload.storage)
        #expect(!bs.isEmpty)
        let nameBytes: [UInt8] = [0x0A, 0x01, 0x63]
        #expect(containsSubsequence(bs, nameBytes))
        let vBytes: [UInt8] = [0x0A, 0x01, 0x76]
        #expect(containsSubsequence(bs, vBytes))
        let asInt42: [UInt8] = [0x31, 0x2A, 0, 0, 0, 0, 0, 0, 0]
        #expect(containsSubsequence(bs, asInt42))
        let temp: [UInt8] = [0x10, 0x02]
        #expect(containsSubsequence(bs, temp))
        let mono: [UInt8] = [0x18, 0x01]
        #expect(containsSubsequence(bs, mono))
    }

    private func containsSubsequence(_ haystack: [UInt8], _ needle: [UInt8]) -> Bool {
        guard !needle.isEmpty, haystack.count >= needle.count else { return false }
        for start in 0...(haystack.count - needle.count) {
            if Array(haystack[start..<start+needle.count]) == needle { return true }
        }
        return false
    }
}
