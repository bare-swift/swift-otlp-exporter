// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes

extension OTLP {
    /// `opentelemetry.proto.common.v1.AnyValue` — 7-way oneof.
    public enum AnyValue: Sendable, Equatable {
        case string(String)
        case bool(Bool)
        case int(Int64)
        case double(Double)
        case array([AnyValue])
        case kvlist([KeyValue])
        case bytes(Bytes)
    }

    /// `opentelemetry.proto.common.v1.KeyValue`.
    public struct KeyValue: Sendable, Equatable {
        public var key: String
        public var value: AnyValue

        public init(key: String, value: AnyValue) {
            self.key = key
            self.value = value
        }
    }

    /// `opentelemetry.proto.resource.v1.Resource`.
    public struct Resource: Sendable, Equatable {
        public var attributes: [KeyValue]
        public var droppedAttributesCount: UInt32

        public init(attributes: [KeyValue] = [], droppedAttributesCount: UInt32 = 0) {
            self.attributes = attributes
            self.droppedAttributesCount = droppedAttributesCount
        }
    }

    /// `opentelemetry.proto.common.v1.InstrumentationScope`.
    public struct InstrumentationScope: Sendable, Equatable {
        public var name: String
        public var version: String
        public var attributes: [KeyValue]
        public var droppedAttributesCount: UInt32

        public init(
            name: String = "",
            version: String = "",
            attributes: [KeyValue] = [],
            droppedAttributesCount: UInt32 = 0
        ) {
            self.name = name
            self.version = version
            self.attributes = attributes
            self.droppedAttributesCount = droppedAttributesCount
        }
    }
}
