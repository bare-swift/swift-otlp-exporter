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
}
