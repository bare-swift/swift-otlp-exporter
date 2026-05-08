// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
// Copyright (c) 2026 The bare-swift Project Authors.

/// Errors thrown by ``OTLP/encode(_:)`` and related encoders.
///
/// **v0.1: this enum has no cases.** OTLP/metrics encoding has no runtime
/// failure modes — encoding pure value-type data has no I/O, and Swift's
/// UTF-8 invariant guarantees valid string bytes. The type exists as a
/// forward-compatible extension point: v0.2's traces/logs may add
/// validation (e.g., span ID length must be 8 bytes; trace ID 16). When
/// that happens, cases will be added without a breaking change to
/// callers using `try?` / `catch`.
public enum OTLPError: Error, Equatable, Sendable {}
