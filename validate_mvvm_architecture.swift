#!/usr/bin/env swift

import Foundation

// MARK: - MVVM + Dependency Injection Architecture Validation Script

enum ArchitectureValidator {
    // MARK: - Validation Results

    struct ValidationReport {
        let mvvmScore: Int
        let dependencyInjectionScore: Int
        let serviceProtocolScore: Int
        let componentArchitectureScore: Int
        let testCoverageScore: Int
        let overallScore: Int
        let violations: [String]
        let recommendations: [String]
        let timestamp: Date

        var complianceLevel: String {
            switch overallScore {
            case 90 ... 100: return "EXCELLENT - Production Ready"
            case 80 ... 89: return "GOOD - Minor Improvements Needed"
            case 70 ... 79: return "ACCEPTABLE - Some Refactoring Required"
            case 60 ... 69: return "POOR - Significant Architecture Issues"
            default: return "CRITICAL - Major Architecture Violations"
            }
        }
    }

    // MARK: - Validation Functions

    static func validateMVVMCompliance() -> (score: Int, violations: [String]) {
        var score = 100
        var violations: [String] = []

        print("🔍 Validating MVVM Architecture Compliance...")

        // Check for proper separation of concerns
        let mvvmFiles = findSwiftFiles()

        // Validate ViewModels
        let viewModelFiles = mvvmFiles.filter { $0.contains("ViewModel") }
        if viewModelFiles.isEmpty {
            violations.append("❌ No ViewModel files found - MVVM pattern not implemented")
            score -= 30
        } else {
            print("✅ Found \(viewModelFiles.count) ViewModel files")
        }

        // Validate Views follow MVVM pattern
        let componentFiles = mvvmFiles.filter { $0.contains("Component") }
        if componentFiles.count >= 8 {
            print("✅ Component library with \(componentFiles.count) components found")
        } else {
            violations.append("⚠️ Expected at least 8 refactored components, found \(componentFiles.count)")
            score -= 10
        }

        // Check for proper protocol usage
        let protocolFiles = mvvmFiles.filter { $0.contains("Protocol") }
        if protocolFiles.isEmpty {
            violations.append("❌ No protocol files found - missing abstraction layer")
            score -= 20
        } else {
            print("✅ Protocol-based architecture detected")
        }

        // Validate MVVMValidation framework exists
        if mvvmFiles.contains("MVVMValidation.swift") {
            print("✅ MVVM validation framework present")
        } else {
            violations.append("⚠️ MVVM validation framework missing")
            score -= 5
        }

        return (score, violations)
    }

    static func validateDependencyInjection() -> (score: Int, violations: [String]) {
        var score = 100
        var violations: [String] = []

        print("🔍 Validating Dependency Injection Implementation...")

        let swiftFiles = findSwiftFiles()

        // Check for ServiceContainer
        let serviceContainerFound = swiftFiles.contains { file in
            let content = readFileContent(file)
            return content.contains("ServiceContainer") || content.contains("service container")
        }

        if serviceContainerFound {
            print("✅ ServiceContainer pattern detected")
        } else {
            violations.append("❌ ServiceContainer implementation not found")
            score -= 25
        }

        // Check for protocol-based services
        let serviceProtocolFiles = swiftFiles.filter { $0.contains("ServiceProtocol") || $0.contains("Service.swift") }
        if serviceProtocolFiles.count >= 3 {
            print("✅ Found \(serviceProtocolFiles.count) service protocols")
        } else {
            violations.append("⚠️ Expected multiple service protocols, found \(serviceProtocolFiles.count)")
            score -= 15
        }

        // Check for mock implementations
        let mockServiceFiles = swiftFiles.filter { $0.contains("Mock") && $0.contains("Service") }
        if mockServiceFiles.count >= 1 {
            print("✅ Mock service implementations found (\(mockServiceFiles.count))")
        } else {
            violations.append("❌ No mock service implementations found")
            score -= 20
        }

        return (score, violations)
    }

    static func validateServiceProtocols() -> (score: Int, violations: [String]) {
        var score = 100
        var violations: [String] = []

        print("🔍 Validating Service Protocol Architecture...")

        let swiftFiles = findSwiftFiles()
        let serviceFiles = swiftFiles.filter { file in
            let content = readFileContent(file)
            return content.contains("protocol") && content.contains("Service")
        }

        if serviceFiles.count >= 12 {
            print("✅ Comprehensive service protocol architecture (\(serviceFiles.count) protocols)")
        } else if serviceFiles.count >= 5 {
            print("✅ Good service protocol coverage (\(serviceFiles.count) protocols)")
            score -= 5
        } else {
            violations.append("⚠️ Insufficient service protocol coverage (\(serviceFiles.count) protocols)")
            score -= 15
        }

        // Check for async/await patterns
        let asyncPatternFound = serviceFiles.contains { file in
            let content = readFileContent(file)
            return content.contains("async") || content.contains("AnyPublisher")
        }

        if asyncPatternFound {
            print("✅ Modern async patterns detected")
        } else {
            violations.append("⚠️ Modern async/await or Combine patterns not found")
            score -= 10
        }

        return (score, violations)
    }

    static func validateComponentArchitecture() -> (score: Int, violations: [String]) {
        var score = 100
        var violations: [String] = []

        print("🔍 Validating Component Architecture...")

        let swiftFiles = findSwiftFiles()
        let componentFiles = swiftFiles.filter { $0.contains("Component") }

        // Check for ReusableComponent protocol usage
        let reusableComponentFound = componentFiles.contains { file in
            let content = readFileContent(file)
            return content.contains("ReusableComponent")
        }

        if reusableComponentFound {
            print("✅ ReusableComponent protocol pattern implemented")
        } else {
            violations.append("❌ ReusableComponent protocol not implemented")
            score -= 20
        }

        // Check for @ViewBuilder patterns
        let viewBuilderFound = componentFiles.contains { file in
            let content = readFileContent(file)
            return content.contains("@ViewBuilder")
        }

        if viewBuilderFound {
            print("✅ @ViewBuilder patterns implemented")
        } else {
            violations.append("⚠️ @ViewBuilder patterns not consistently used")
            score -= 10
        }

        // Check for configuration objects
        let configurationFound = componentFiles.contains { file in
            let content = readFileContent(file)
            return content.contains("Configuration") && content.contains("ComponentConfiguration")
        }

        if configurationFound {
            print("✅ Configuration pattern implemented")
        } else {
            violations.append("⚠️ Component configuration pattern not found")
            score -= 15
        }

        return (score, violations)
    }

    static func validateTestCoverage() -> (score: Int, violations: [String]) {
        var score = 100
        var violations: [String] = []

        print("🔍 Validating Test Coverage...")

        let swiftFiles = findSwiftFiles()
        let testFiles = swiftFiles.filter { $0.contains("Tests") || $0.contains("Test.swift") }

        if testFiles.count >= 3 {
            print("✅ Comprehensive test coverage (\(testFiles.count) test files)")
        } else if testFiles.count >= 1 {
            print("✅ Basic test coverage (\(testFiles.count) test files)")
            score -= 20
        } else {
            violations.append("❌ No test files found")
            score -= 40
        }

        // Check for XCTest usage
        let xcTestFound = testFiles.contains { file in
            let content = readFileContent(file)
            return content.contains("XCTest") && content.contains("import XCTest")
        }

        if xcTestFound {
            print("✅ XCTest framework properly used")
        } else if !testFiles.isEmpty {
            violations.append("⚠️ Test files found but XCTest framework not properly imported")
            score -= 15
        }

        // Check for mock testing
        let mockTestingFound = testFiles.contains { file in
            let content = readFileContent(file)
            return content.contains("Mock") && content.contains("Service")
        }

        if mockTestingFound {
            print("✅ Mock-based testing implemented")
        } else {
            violations.append("⚠️ Mock-based testing not implemented")
            score -= 10
        }

        return (score, violations)
    }

    // MARK: - Utility Functions

    static func findSwiftFiles() -> [String] {
        let fileManager = FileManager.default
        let currentDirectory = fileManager.currentDirectoryPath

        var swiftFiles: [String] = []

        if let enumerator = fileManager.enumerator(atPath: currentDirectory) {
            while let element = enumerator.nextObject() as? String {
                if element.hasSuffix(".swift"), !element.contains(".build"), !element.contains("DerivedData") {
                    swiftFiles.append(element)
                }
            }
        }

        return swiftFiles
    }

    static func readFileContent(_ filePath: String) -> String {
        let fileManager = FileManager.default
        let currentDirectory = fileManager.currentDirectoryPath
        let fullPath = "\(currentDirectory)/\(filePath)"

        guard let content = try? String(contentsOfFile: fullPath, encoding: .utf8) else {
            return ""
        }

        return content
    }

    static func runValidation() -> ValidationReport {
        print("🚀 Starting HobbyistSwiftUI MVVM + Dependency Injection Architecture Validation")
        print("=" * 80)

        let mvvmResult = validateMVVMCompliance()
        let diResult = validateDependencyInjection()
        let serviceResult = validateServiceProtocols()
        let componentResult = validateComponentArchitecture()
        let testResult = validateTestCoverage()

        let overallScore = (mvvmResult.score + diResult.score + serviceResult.score + componentResult.score + testResult.score) / 5

        let allViolations = mvvmResult.violations + diResult.violations + serviceResult.violations + componentResult.violations + testResult.violations

        let recommendations = generateRecommendations(
            mvvmScore: mvvmResult.score,
            diScore: diResult.score,
            serviceScore: serviceResult.score,
            componentScore: componentResult.score,
            testScore: testResult.score
        )

        return ValidationReport(
            mvvmScore: mvvmResult.score,
            dependencyInjectionScore: diResult.score,
            serviceProtocolScore: serviceResult.score,
            componentArchitectureScore: componentResult.score,
            testCoverageScore: testResult.score,
            overallScore: overallScore,
            violations: allViolations,
            recommendations: recommendations,
            timestamp: Date()
        )
    }

    static func generateRecommendations(mvvmScore: Int, diScore: Int, serviceScore: Int, componentScore: Int, testScore: Int) -> [String] {
        var recommendations: [String] = []

        if mvvmScore < 80 {
            recommendations.append("🔧 Implement proper MVVM separation with dedicated ViewModels for business logic")
            recommendations.append("📚 Add @Published properties and ObservableObject conformance to ViewModels")
        }

        if diScore < 80 {
            recommendations.append("🏗️ Implement comprehensive ServiceContainer for dependency injection")
            recommendations.append("🔗 Create protocol-based service abstractions with mock implementations")
        }

        if serviceScore < 80 {
            recommendations.append("⚙️ Expand service protocol architecture to cover all business domains")
            recommendations.append("🔄 Implement modern async/await or Combine patterns for asynchronous operations")
        }

        if componentScore < 80 {
            recommendations.append("🧩 Implement ReusableComponent protocol across all UI components")
            recommendations.append("🏗️ Add configuration objects and @ViewBuilder patterns for flexible composition")
        }

        if testScore < 80 {
            recommendations.append("🧪 Increase test coverage with comprehensive unit and integration tests")
            recommendations.append("🎭 Implement mock-based testing for all service protocols")
        }

        return recommendations
    }

    static func printReport(_ report: ValidationReport) {
        print("\n" + "=" * 80)
        print("📊 MVVM + DEPENDENCY INJECTION ARCHITECTURE VALIDATION REPORT")
        print("=" * 80)
        print("Generated: \(report.timestamp.formatted())")
        print("")

        print("🎯 OVERALL SCORE: \(report.overallScore)/100 - \(report.complianceLevel)")
        print("")

        print("📈 DETAILED SCORES:")
        print("• MVVM Compliance: \(report.mvvmScore)/100")
        print("• Dependency Injection: \(report.dependencyInjectionScore)/100")
        print("• Service Protocols: \(report.serviceProtocolScore)/100")
        print("• Component Architecture: \(report.componentArchitectureScore)/100")
        print("• Test Coverage: \(report.testCoverageScore)/100")
        print("")

        if !report.violations.isEmpty {
            print("⚠️  VIOLATIONS & ISSUES:")
            for violation in report.violations {
                print("  \(violation)")
            }
            print("")
        }

        if !report.recommendations.isEmpty {
            print("💡 RECOMMENDATIONS:")
            for recommendation in report.recommendations {
                print("  \(recommendation)")
            }
            print("")
        }

        print("🏆 ARCHITECTURE ACHIEVEMENTS:")
        if report.overallScore >= 90 {
            print("  ✅ Enterprise-grade MVVM + DI implementation")
            print("  ✅ Production-ready architecture")
            print("  ✅ Comprehensive testing infrastructure")
        } else if report.overallScore >= 80 {
            print("  ✅ Solid MVVM + DI foundation")
            print("  ✅ Good architectural patterns")
            print("  ⚠️ Minor improvements needed for production")
        } else {
            print("  ⚠️ Architecture needs significant improvement")
            print("  🔧 Focus on implementing missing patterns")
        }

        print("")
        print("=" * 80)
    }
}

// MARK: - Main Execution

extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// Run the validation
let report = ArchitectureValidator.runValidation()
ArchitectureValidator.printReport(report)

// Exit with appropriate code
if report.overallScore >= 80 {
    print("✅ Architecture validation PASSED")
    exit(0)
} else {
    print("❌ Architecture validation FAILED - Improvements needed")
    exit(1)
}
