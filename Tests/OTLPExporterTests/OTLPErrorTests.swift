// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

import Testing
@testable import OTLPExporter

@Suite("OTLPError")
struct OTLPErrorTests {
    @Test("OTLPError is Sendable and Error (uninhabited type — reserved for v0.2)")
    func conformances() {
        let _: any Error.Type = OTLPError.self
        let _: any Sendable.Type = OTLPError.self
    }
}
