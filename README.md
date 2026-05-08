# swift-otlp-exporter

Sendable, Foundation-free [OpenTelemetry OTLP](https://opentelemetry.io/docs/specs/otlp/) wire-format encoder for Swift 6. Encodes metrics for **OTLP/HTTP+protobuf** — the production-canonical OTLP transport.

Pure encoder — no HTTP transport. Output is [`Bytes`](https://github.com/bare-swift/swift-bytes) ready as the body of an `HTTP POST /v1/metrics` request to an OTLP collector with `Content-Type: application/x-protobuf`.

Part of the [bare-swift](https://github.com/bare-swift) ecosystem.

## Install

```swift
.package(url: "https://github.com/bare-swift/swift-otlp-exporter.git", from: "0.1.0")
```

```swift
.product(name: "OTLPExporter", package: "swift-otlp-exporter")
```

## Usage

```swift
import OTLPExporter
import Bytes

let request = OTLP.ExportMetricsServiceRequest(
    resourceMetrics: [
        OTLP.ResourceMetrics(
            resource: OTLP.Resource(attributes: [
                OTLP.KeyValue(key: "service.name", value: .string("api")),
            ]),
            scopeMetrics: [
                OTLP.ScopeMetrics(
                    scope: OTLP.InstrumentationScope(name: "myapp", version: "1.0"),
                    metrics: [
                        OTLP.Metric(
                            name: "http_requests",
                            description: "Total HTTP requests",
                            unit: "1",
                            data: .sum(OTLP.Sum(
                                dataPoints: [
                                    {
                                        var dp = OTLP.NumberDataPoint(
                                            attributes: [.init(key: "method", value: .string("GET"))],
                                            startTimeUnixNano: 1_700_000_000_000_000_000,
                                            timeUnixNano:      1_700_000_060_000_000_000
                                        )
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
    ]
)

let payload: Bytes = OTLP.encode(request)
// HTTP POST /v1/metrics, Content-Type: application/x-protobuf, body = payload.storage
```

## Scope

**v0.1 covers:** OTLP metrics over HTTP+protobuf only. All five OTLP metric types (Gauge, Sum, Histogram, ExponentialHistogram, Summary), Resource and InstrumentationScope attributes, Exemplars, AggregationTemporality.

**Out of scope (deferred):** traces, logs, gRPC transport, JSON OTLP, the HTTP transport itself, decoder. Adapters from `swift-prometheus` / `swift-hdrhistogram` / `swift-ddsketch` will ship as separate packages.

## Documentation

Full DocC documentation: <https://bare-swift.github.io/swift-otlp-exporter/>

## License

Apache 2.0 with LLVM exception. See [LICENSE](./LICENSE) and [NOTICE](./NOTICE).
