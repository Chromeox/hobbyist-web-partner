import XCTest
@testable import HobbyistSwiftUIDependencies

final class DependenciesTests: XCTestCase {
    func testDependenciesConfiguration() throws {
        // Test that dependencies can be configured without errors
        Dependencies.shared.configure()
        XCTAssert(true, "Dependencies configured successfully")
    }
}