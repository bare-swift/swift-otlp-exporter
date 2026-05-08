// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes

extension OTLP {
    /// `opentelemetry.proto.metrics.v1.AggregationTemporality`.
    public enum AggregationTemporality: UInt32, Sendable, Equatable {
        case unspecified = 0
        case delta       = 1
        case cumulative  = 2
    }

    /// `opentelemetry.proto.metrics.v1.Exemplar`.
    public struct Exemplar: Sendable, Equatable {
        public enum Value: Sendable, Equatable {
            case asDouble(Double)
            case asInt(Int64)
        }

        public var filteredAttributes: [KeyValue]
        public var timeUnixNano: UInt64
        public var value: Value?
        public var spanID: Bytes
        public var traceID: Bytes

        public init(
            filteredAttributes: [KeyValue] = [],
            timeUnixNano: UInt64 = 0,
            value: Value? = nil,
            spanID: Bytes = Bytes(),
            traceID: Bytes = Bytes()
        ) {
            self.filteredAttributes = filteredAttributes
            self.timeUnixNano = timeUnixNano
            self.value = value
            self.spanID = spanID
            self.traceID = traceID
        }
    }

    /// `opentelemetry.proto.metrics.v1.SummaryDataPoint.ValueAtQuantile`.
    public struct ValueAtQuantile: Sendable, Equatable {
        public var quantile: Double
        public var value: Double
        public init(quantile: Double = 0.0, value: Double = 0.0) {
            self.quantile = quantile
            self.value = value
        }
    }

    /// `opentelemetry.proto.metrics.v1.SummaryDataPoint`.
    public struct SummaryDataPoint: Sendable, Equatable {
        public var attributes: [KeyValue]
        public var startTimeUnixNano: UInt64
        public var timeUnixNano: UInt64
        public var count: UInt64
        public var sum: Double
        public var quantileValues: [ValueAtQuantile]
        public var flags: UInt32

        public init(
            attributes: [KeyValue] = [],
            startTimeUnixNano: UInt64 = 0,
            timeUnixNano: UInt64 = 0,
            count: UInt64 = 0,
            sum: Double = 0.0,
            quantileValues: [ValueAtQuantile] = [],
            flags: UInt32 = 0
        ) {
            self.attributes = attributes
            self.startTimeUnixNano = startTimeUnixNano
            self.timeUnixNano = timeUnixNano
            self.count = count
            self.sum = sum
            self.quantileValues = quantileValues
            self.flags = flags
        }
    }

    /// `opentelemetry.proto.metrics.v1.Summary`.
    public struct Summary: Sendable, Equatable {
        public var dataPoints: [SummaryDataPoint]
        public init(dataPoints: [SummaryDataPoint] = []) {
            self.dataPoints = dataPoints
        }
    }

    /// `opentelemetry.proto.metrics.v1.ExponentialHistogramDataPoint.Buckets`.
    public struct Buckets: Sendable, Equatable {
        public var offset: Int32
        public var bucketCounts: [UInt64]

        public init(offset: Int32 = 0, bucketCounts: [UInt64] = []) {
            self.offset = offset
            self.bucketCounts = bucketCounts
        }
    }

    /// `opentelemetry.proto.metrics.v1.ExponentialHistogramDataPoint`.
    public struct ExponentialHistogramDataPoint: Sendable, Equatable {
        public var attributes: [KeyValue]
        public var startTimeUnixNano: UInt64
        public var timeUnixNano: UInt64
        public var count: UInt64
        public var sum: Double
        public var scale: Int32
        public var zeroCount: UInt64
        public var positive: Buckets
        public var negative: Buckets
        public var flags: UInt32
        public var exemplars: [Exemplar]
        public var min: Double?
        public var max: Double?
        public var zeroThreshold: Double

        public init(
            attributes: [KeyValue] = [],
            startTimeUnixNano: UInt64 = 0,
            timeUnixNano: UInt64 = 0,
            count: UInt64 = 0,
            sum: Double = 0.0,
            scale: Int32 = 0,
            zeroCount: UInt64 = 0,
            positive: Buckets = Buckets(),
            negative: Buckets = Buckets(),
            flags: UInt32 = 0,
            exemplars: [Exemplar] = [],
            min: Double? = nil,
            max: Double? = nil,
            zeroThreshold: Double = 0.0
        ) {
            self.attributes = attributes
            self.startTimeUnixNano = startTimeUnixNano
            self.timeUnixNano = timeUnixNano
            self.count = count
            self.sum = sum
            self.scale = scale
            self.zeroCount = zeroCount
            self.positive = positive
            self.negative = negative
            self.flags = flags
            self.exemplars = exemplars
            self.min = min
            self.max = max
            self.zeroThreshold = zeroThreshold
        }
    }

    /// `opentelemetry.proto.metrics.v1.ExponentialHistogram`.
    public struct ExponentialHistogram: Sendable, Equatable {
        public var dataPoints: [ExponentialHistogramDataPoint]
        public var aggregationTemporality: AggregationTemporality

        public init(
            dataPoints: [ExponentialHistogramDataPoint] = [],
            aggregationTemporality: AggregationTemporality = .unspecified
        ) {
            self.dataPoints = dataPoints
            self.aggregationTemporality = aggregationTemporality
        }
    }

    /// `opentelemetry.proto.metrics.v1.HistogramDataPoint`.
    public struct HistogramDataPoint: Sendable, Equatable {
        public var attributes: [KeyValue]
        public var startTimeUnixNano: UInt64
        public var timeUnixNano: UInt64
        public var count: UInt64
        public var sum: Double?
        public var bucketCounts: [UInt64]
        public var explicitBounds: [Double]
        public var exemplars: [Exemplar]
        public var flags: UInt32
        public var min: Double?
        public var max: Double?

        public init(
            attributes: [KeyValue] = [],
            startTimeUnixNano: UInt64 = 0,
            timeUnixNano: UInt64 = 0,
            count: UInt64 = 0,
            sum: Double? = nil,
            bucketCounts: [UInt64] = [],
            explicitBounds: [Double] = [],
            exemplars: [Exemplar] = [],
            flags: UInt32 = 0,
            min: Double? = nil,
            max: Double? = nil
        ) {
            self.attributes = attributes
            self.startTimeUnixNano = startTimeUnixNano
            self.timeUnixNano = timeUnixNano
            self.count = count
            self.sum = sum
            self.bucketCounts = bucketCounts
            self.explicitBounds = explicitBounds
            self.exemplars = exemplars
            self.flags = flags
            self.min = min
            self.max = max
        }
    }

    /// `opentelemetry.proto.metrics.v1.Histogram`.
    public struct Histogram: Sendable, Equatable {
        public var dataPoints: [HistogramDataPoint]
        public var aggregationTemporality: AggregationTemporality

        public init(
            dataPoints: [HistogramDataPoint] = [],
            aggregationTemporality: AggregationTemporality = .unspecified
        ) {
            self.dataPoints = dataPoints
            self.aggregationTemporality = aggregationTemporality
        }
    }

    /// `opentelemetry.proto.metrics.v1.Gauge`.
    public struct Gauge: Sendable, Equatable {
        public var dataPoints: [NumberDataPoint]
        public init(dataPoints: [NumberDataPoint] = []) {
            self.dataPoints = dataPoints
        }
    }

    /// `opentelemetry.proto.metrics.v1.Sum`.
    public struct Sum: Sendable, Equatable {
        public var dataPoints: [NumberDataPoint]
        public var aggregationTemporality: AggregationTemporality
        public var isMonotonic: Bool

        public init(
            dataPoints: [NumberDataPoint] = [],
            aggregationTemporality: AggregationTemporality = .unspecified,
            isMonotonic: Bool = false
        ) {
            self.dataPoints = dataPoints
            self.aggregationTemporality = aggregationTemporality
            self.isMonotonic = isMonotonic
        }
    }

    /// `opentelemetry.proto.metrics.v1.NumberDataPoint`.
    public struct NumberDataPoint: Sendable, Equatable {
        public enum Value: Sendable, Equatable {
            case asDouble(Double)
            case asInt(Int64)
        }

        public var attributes: [KeyValue]
        public var startTimeUnixNano: UInt64
        public var timeUnixNano: UInt64
        public var value: Value?
        public var exemplars: [Exemplar]
        public var flags: UInt32

        public init(
            attributes: [KeyValue] = [],
            startTimeUnixNano: UInt64 = 0,
            timeUnixNano: UInt64 = 0,
            value: Value? = nil,
            exemplars: [Exemplar] = [],
            flags: UInt32 = 0
        ) {
            self.attributes = attributes
            self.startTimeUnixNano = startTimeUnixNano
            self.timeUnixNano = timeUnixNano
            self.value = value
            self.exemplars = exemplars
            self.flags = flags
        }
    }
}
