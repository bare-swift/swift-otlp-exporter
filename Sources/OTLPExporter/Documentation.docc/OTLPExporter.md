# ``OTLPExporter``

Sendable, Foundation-free OpenTelemetry OTLP/metrics encoder over HTTP+protobuf.

## Overview

`swift-otlp-exporter` produces ready-to-send HTTP request bodies in the
OTLP/protobuf wire format. Pure encoder — no HTTP transport, no
aggregation. Caller wires their HTTP client of choice and sends the
returned `Bytes` to `POST /v1/metrics` with `Content-Type:
application/x-protobuf`.

```swift
import OTLPExporter

let request = OTLP.ExportMetricsServiceRequest(resourceMetrics: [
    // ... build OTLP-shaped data ...
])
let payload = OTLP.encode(request)  // Bytes ready for HTTP POST
```

The public Swift types mirror the OTLP proto schema 1:1. A reader of
`opentelemetry-proto/metrics/v1/metrics.proto` finds every field as a
Swift property of the same name.

## Topics

### Top-level

- ``OTLP``

### Errors

- ``OTLPError``
