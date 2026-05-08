# Test-parity exceptions

Per [RFC-0002](https://github.com/bare-swift/bare-swift/blob/main/rfcs/0002-test-parity-policy.md) and its 2026-05-07 amendment per [RFC-0004](https://github.com/bare-swift/bare-swift/blob/main/rfcs/0004-inline-test-vectors.md), this file documents how `swift-otlp-exporter` validates correctness.

## Source: opentelemetry-proto + protobuf wire-format spec

There is no upstream Rust crate to track parity against. Two layers of correctness:

1. **Wire-format primitives** (`ProtoWriter`) — the protobuf wire format spec is the source of truth. Test vectors for varint, fixed I32/I64, length-delimited, and packed-repeated are derived directly from the spec
   (https://protobuf.dev/programming-guides/encoding/) and verifiable by hand against it.

2. **OTLP message encoding** — the OTLP proto schema
   (https://github.com/open-telemetry/opentelemetry-proto/tree/main/opentelemetry/proto)
   is the source of truth for field numbers, wire types, oneof shapes,
   and proto3 optional/default semantics. Test vectors for OTLP messages
   compose mechanically from the wire-format primitives applied per the
   schema.

Test layout:

- `ProtoWriterTests.swift` — wire-format primitives (varint, I32, I64, length-delimited, packed-repeated, ZigZag).
- `CommonEncodingTests.swift` — `KeyValue`, `AnyValue` (all 7 oneof cases), `Resource`, `InstrumentationScope`.
- `NumberDataPointTests.swift` — `NumberDataPoint`, `Exemplar`, `AggregationTemporality`.
- `GaugeSumEncodingTests.swift` — `Gauge`, `Sum`.
- `HistogramEncodingTests.swift` — `HistogramDataPoint`, `Histogram`.
- `ExponentialHistogramEncodingTests.swift` — `Buckets`, `ExponentialHistogramDataPoint`, `ExponentialHistogram`.
- `SummaryEncodingTests.swift` — `ValueAtQuantile`, `SummaryDataPoint`, `Summary`.
- `EndToEndTests.swift` — full `ExportMetricsServiceRequest` with multi-resource, multi-scope, multi-metric content.

## Out of scope for v0.1 (no Swift counterpart)

- Traces (Span, Status, Link, Event) — separate proto schema. Defer to v0.2.
- Logs (LogRecord, SeverityNumber) — separate proto schema. Defer to v0.2.
- gRPC transport — length-prefix framing + status codes. Defer to v0.3+.
- JSON OTLP — defined in spec but rarely used in production. Defer to v0.3+.
- HTTP transport — caller wires URLSession / async-http-client / NIO.
- Decoder — exporter is write-only.

## Refresh

When the OTLP proto schema changes (rare; OTLP 1.x has been stable),
re-read the proto and update tests for any affected message. Record
source pins here when refreshing:

- opentelemetry-proto: tracked at upstream commit (record at next refresh).
- protobuf wire format spec: stable since 2008; no pin needed.
