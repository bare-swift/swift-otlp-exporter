// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

import Bytes

/// Sendable, Foundation-free OpenTelemetry OTLP/metrics encoder over HTTP+protobuf.
///
/// Pure encoder — no HTTP transport. Use ``ExportMetricsServiceRequest`` to
/// build a request, then ``encode(_:)`` returns the protobuf-encoded `Bytes`
/// ready as the body of `HTTP POST /v1/metrics` with
/// `Content-Type: application/x-protobuf`.
///
/// Public types mirror the OTLP proto schema 1:1. A reader of
/// `opentelemetry-proto/metrics/v1/metrics.proto` finds every field as a
/// Swift property of the same name.
public enum OTLP: Sendable {}

extension OTLP {
    /// Encode an ``OTLP/ExportMetricsServiceRequest`` to its protobuf wire form.
    /// The returned `Bytes` is the body for `HTTP POST /v1/metrics` with
    /// `Content-Type: application/x-protobuf`.
    public static func encode(_ request: ExportMetricsServiceRequest) -> Bytes {
        EncodeMetrics.encodeExportMetricsServiceRequest(request)
    }
}
