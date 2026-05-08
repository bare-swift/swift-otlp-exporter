# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.1.0] - 2026-05-08

### Added
- `OTLP.encode(_:)` — Sendable, Foundation-free, non-throwing encoder of `OTLP.ExportMetricsServiceRequest` to protobuf wire bytes ready for `HTTP POST /v1/metrics`.
- All five OTLP metric types: `OTLP.Gauge`, `OTLP.Sum`, `OTLP.Histogram`, `OTLP.ExponentialHistogram`, `OTLP.Summary`.
- All four data point types: `OTLP.NumberDataPoint`, `OTLP.HistogramDataPoint`, `OTLP.ExponentialHistogramDataPoint`, `OTLP.SummaryDataPoint`.
- Full attribute support via `OTLP.KeyValue` and 7-way `OTLP.AnyValue` (string/bool/int/double/bytes/array/kvlist).
- `OTLP.Resource`, `OTLP.InstrumentationScope`, `OTLP.Exemplar`, `OTLP.AggregationTemporality` (delta / cumulative / unspecified).
- `OTLPError` typed-error enum (no cases in v0.1; reserved as a forward-compatible extension point for v0.2 trace/log validation).
- DocC documentation, full README example, NOTICE crediting OpenTelemetry's opentelemetry-proto.

### Dependencies
- `swift-bytes 0.1.0` — output buffer.
- `swift-varint 0.1.0` — LEB128 unsigned for protobuf VARINT wire type and ZigZag for `sint32` (used by `Buckets.offset` and `ExponentialHistogramDataPoint.scale`).
- **Second inter-package dependency** in the bare-swift ecosystem; **first to take two intra-ecosystem deps**.

### Limitations (out of scope for v0.1)
- Traces (Span, Status, Link, Event). Defer to v0.2.
- Logs (LogRecord, SeverityNumber). Defer to v0.2.
- gRPC transport (length-prefix framing + status codes). Defer to v0.3+.
- JSON OTLP variant. Defer to v0.3+.
- HTTP transport itself — caller wires URLSession / async-http-client / NIO.
- Decoder — exporter is write-only.
- Adapters from `swift-prometheus` / `swift-hdrhistogram` / `swift-ddsketch` — separate packages.
