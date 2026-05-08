// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes

/// Internal per-metric-type encoders. Each function produces the inner
/// protobuf payload for one OTLP message; callers wrap with tag+length
/// when embedding (via `ProtoWriter.writeMessage`).
enum EncodeMetrics {
    // MARK: - Exemplar
    static func encodeExemplar(_ e: OTLP.Exemplar) -> Bytes {
        var w = ProtoWriter()
        w.writeFixed64(e.timeUnixNano, fieldNumber: 2)
        if let v = e.value {
            switch v {
            case .asDouble(let d):
                w.writeTag(field: 3, wireType: .i64)
                w.writeI64(d.bitPattern)
            case .asInt(let i):
                w.writeTag(field: 6, wireType: .i64)
                w.writeI64(UInt64(bitPattern: i))
            }
        }
        w.writeBytes(e.spanID, fieldNumber: 4)
        w.writeBytes(e.traceID, fieldNumber: 5)
        for kv in e.filteredAttributes {
            let kvb = Encoder.encodeKeyValue(kv)
            w.writeMessage(kvb, fieldNumber: 7)
        }
        return w.finish()
    }

    // MARK: - NumberDataPoint
    static func encodeNumberDataPoint(_ p: OTLP.NumberDataPoint) -> Bytes {
        var w = ProtoWriter()
        w.writeFixed64(p.startTimeUnixNano, fieldNumber: 2)
        w.writeFixed64(p.timeUnixNano, fieldNumber: 3)
        if let v = p.value {
            switch v {
            case .asDouble(let d):
                w.writeTag(field: 4, wireType: .i64)
                w.writeI64(d.bitPattern)
            case .asInt(let i):
                w.writeTag(field: 6, wireType: .i64)
                w.writeI64(UInt64(bitPattern: i))
            }
        }
        for e in p.exemplars {
            let eb = encodeExemplar(e)
            w.writeMessage(eb, fieldNumber: 5)
        }
        for kv in p.attributes {
            let kvb = Encoder.encodeKeyValue(kv)
            w.writeMessage(kvb, fieldNumber: 7)
        }
        w.writeUInt32(p.flags, fieldNumber: 8)
        return w.finish()
    }

    // MARK: - Gauge
    static func encodeGauge(_ g: OTLP.Gauge) -> Bytes {
        var w = ProtoWriter()
        for dp in g.dataPoints {
            let dpb = encodeNumberDataPoint(dp)
            w.writeMessage(dpb, fieldNumber: 1)
        }
        return w.finish()
    }

    // MARK: - Sum
    static func encodeSum(_ s: OTLP.Sum) -> Bytes {
        var w = ProtoWriter()
        for dp in s.dataPoints {
            let dpb = encodeNumberDataPoint(dp)
            w.writeMessage(dpb, fieldNumber: 1)
        }
        w.writeEnum(s.aggregationTemporality.rawValue, fieldNumber: 2)
        w.writeBool(s.isMonotonic, fieldNumber: 3)
        return w.finish()
    }

    // MARK: - HistogramDataPoint
    static func encodeHistogramDataPoint(_ dp: OTLP.HistogramDataPoint) -> Bytes {
        var w = ProtoWriter()
        w.writeFixed64(dp.startTimeUnixNano, fieldNumber: 2)
        w.writeFixed64(dp.timeUnixNano, fieldNumber: 3)
        w.writeFixed64(dp.count, fieldNumber: 4)
        w.writeOptionalDouble(dp.sum, fieldNumber: 5)
        w.writePackedFixed64(dp.bucketCounts, fieldNumber: 6)
        w.writePackedDouble(dp.explicitBounds, fieldNumber: 7)
        for e in dp.exemplars {
            let eb = encodeExemplar(e)
            w.writeMessage(eb, fieldNumber: 8)
        }
        for kv in dp.attributes {
            let kvb = Encoder.encodeKeyValue(kv)
            w.writeMessage(kvb, fieldNumber: 9)
        }
        w.writeUInt32(dp.flags, fieldNumber: 10)
        w.writeOptionalDouble(dp.min, fieldNumber: 11)
        w.writeOptionalDouble(dp.max, fieldNumber: 12)
        return w.finish()
    }

    // MARK: - Histogram
    static func encodeHistogram(_ h: OTLP.Histogram) -> Bytes {
        var w = ProtoWriter()
        for dp in h.dataPoints {
            let dpb = encodeHistogramDataPoint(dp)
            w.writeMessage(dpb, fieldNumber: 1)
        }
        w.writeEnum(h.aggregationTemporality.rawValue, fieldNumber: 2)
        return w.finish()
    }

    // MARK: - Buckets
    static func encodeBuckets(_ b: OTLP.Buckets) -> Bytes {
        var w = ProtoWriter()
        w.writeSInt32(b.offset, fieldNumber: 1)
        w.writePackedUInt64(b.bucketCounts, fieldNumber: 2)
        return w.finish()
    }

    // MARK: - ExponentialHistogramDataPoint
    static func encodeExponentialHistogramDataPoint(
        _ dp: OTLP.ExponentialHistogramDataPoint
    ) -> Bytes {
        var w = ProtoWriter()
        for kv in dp.attributes {
            let kvb = Encoder.encodeKeyValue(kv)
            w.writeMessage(kvb, fieldNumber: 1)
        }
        w.writeFixed64(dp.startTimeUnixNano, fieldNumber: 2)
        w.writeFixed64(dp.timeUnixNano, fieldNumber: 3)
        w.writeFixed64(dp.count, fieldNumber: 4)
        w.writeDouble(dp.sum, fieldNumber: 5)
        w.writeSInt32(dp.scale, fieldNumber: 6)
        w.writeFixed64(dp.zeroCount, fieldNumber: 7)
        let pos = encodeBuckets(dp.positive)
        if !pos.isEmpty {
            w.writeMessage(pos, fieldNumber: 8)
        }
        let neg = encodeBuckets(dp.negative)
        if !neg.isEmpty {
            w.writeMessage(neg, fieldNumber: 9)
        }
        w.writeUInt32(dp.flags, fieldNumber: 10)
        for e in dp.exemplars {
            let eb = encodeExemplar(e)
            w.writeMessage(eb, fieldNumber: 11)
        }
        w.writeOptionalDouble(dp.min, fieldNumber: 12)
        w.writeOptionalDouble(dp.max, fieldNumber: 13)
        w.writeDouble(dp.zeroThreshold, fieldNumber: 14)
        return w.finish()
    }

    // MARK: - ExponentialHistogram
    static func encodeExponentialHistogram(_ h: OTLP.ExponentialHistogram) -> Bytes {
        var w = ProtoWriter()
        for dp in h.dataPoints {
            let dpb = encodeExponentialHistogramDataPoint(dp)
            w.writeMessage(dpb, fieldNumber: 1)
        }
        w.writeEnum(h.aggregationTemporality.rawValue, fieldNumber: 2)
        return w.finish()
    }

    // MARK: - ValueAtQuantile
    static func encodeValueAtQuantile(_ v: OTLP.ValueAtQuantile) -> Bytes {
        var w = ProtoWriter()
        w.writeDouble(v.quantile, fieldNumber: 1)
        w.writeDouble(v.value, fieldNumber: 2)
        return w.finish()
    }

    // MARK: - SummaryDataPoint
    static func encodeSummaryDataPoint(_ dp: OTLP.SummaryDataPoint) -> Bytes {
        var w = ProtoWriter()
        w.writeFixed64(dp.startTimeUnixNano, fieldNumber: 2)
        w.writeFixed64(dp.timeUnixNano, fieldNumber: 3)
        w.writeFixed64(dp.count, fieldNumber: 4)
        w.writeDouble(dp.sum, fieldNumber: 5)
        for v in dp.quantileValues {
            let vb = encodeValueAtQuantile(v)
            w.writeMessage(vb, fieldNumber: 6)
        }
        for kv in dp.attributes {
            let kvb = Encoder.encodeKeyValue(kv)
            w.writeMessage(kvb, fieldNumber: 7)
        }
        w.writeUInt32(dp.flags, fieldNumber: 8)
        return w.finish()
    }

    // MARK: - Summary
    static func encodeSummary(_ s: OTLP.Summary) -> Bytes {
        var w = ProtoWriter()
        for dp in s.dataPoints {
            let dpb = encodeSummaryDataPoint(dp)
            w.writeMessage(dpb, fieldNumber: 1)
        }
        return w.finish()
    }

    // MARK: - Metric (oneof data)
    static func encodeMetric(_ m: OTLP.Metric) -> Bytes {
        var w = ProtoWriter()
        w.writeString(m.name, fieldNumber: 1)
        w.writeString(m.description, fieldNumber: 2)
        w.writeString(m.unit, fieldNumber: 3)
        if let data = m.data {
            switch data {
            case .gauge(let g):
                let gb = encodeGauge(g)
                w.writeMessage(gb, fieldNumber: 5)
            case .sum(let s):
                let sb = encodeSum(s)
                w.writeMessage(sb, fieldNumber: 7)
            case .histogram(let h):
                let hb = encodeHistogram(h)
                w.writeMessage(hb, fieldNumber: 9)
            case .exponentialHistogram(let h):
                let hb = encodeExponentialHistogram(h)
                w.writeMessage(hb, fieldNumber: 10)
            case .summary(let s):
                let sb = encodeSummary(s)
                w.writeMessage(sb, fieldNumber: 11)
            }
        }
        for kv in m.metadata {
            let kvb = Encoder.encodeKeyValue(kv)
            w.writeMessage(kvb, fieldNumber: 12)
        }
        return w.finish()
    }

    // MARK: - ScopeMetrics
    static func encodeScopeMetrics(_ sm: OTLP.ScopeMetrics) -> Bytes {
        var w = ProtoWriter()
        let scopeBytes = Encoder.encodeInstrumentationScope(sm.scope)
        if !scopeBytes.isEmpty {
            w.writeMessage(scopeBytes, fieldNumber: 1)
        }
        for m in sm.metrics {
            let mb = encodeMetric(m)
            w.writeMessage(mb, fieldNumber: 2)
        }
        w.writeString(sm.schemaURL, fieldNumber: 3)
        return w.finish()
    }

    // MARK: - ResourceMetrics
    static func encodeResourceMetrics(_ rm: OTLP.ResourceMetrics) -> Bytes {
        var w = ProtoWriter()
        let resourceBytes = Encoder.encodeResource(rm.resource)
        if !resourceBytes.isEmpty {
            w.writeMessage(resourceBytes, fieldNumber: 1)
        }
        for sm in rm.scopeMetrics {
            let smb = encodeScopeMetrics(sm)
            w.writeMessage(smb, fieldNumber: 2)
        }
        w.writeString(rm.schemaURL, fieldNumber: 3)
        return w.finish()
    }

    // MARK: - ExportMetricsServiceRequest
    static func encodeExportMetricsServiceRequest(
        _ req: OTLP.ExportMetricsServiceRequest
    ) -> Bytes {
        var w = ProtoWriter()
        for rm in req.resourceMetrics {
            let rmb = encodeResourceMetrics(rm)
            w.writeMessage(rmb, fieldNumber: 1)
        }
        return w.finish()
    }
}
