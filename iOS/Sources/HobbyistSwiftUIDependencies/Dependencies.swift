// Dependencies.swift
// HobbyistSwiftUI Dependencies Module
// 
// This file re-exports all the third-party dependencies used by the iOS app
// to make them available through a single import statement.

// Re-export Supabase modules
@_exported import Supabase
@_exported import Auth
@_exported import Realtime
@_exported import Storage
@_exported import Functions

// Re-export Stripe modules
@_exported import StripePaymentSheet
@_exported import StripePayments
@_exported import StripeCore

// Re-export Kingfisher
@_exported import Kingfisher

// MARK: - Dependency Container

public struct Dependencies {
    public static let shared = Dependencies()
    
    private init() {}
    
    /// Provides centralized dependency configuration
    public func configure() {
        // Any global dependency configuration can go here
        print("📦 HobbyistSwiftUI Dependencies configured successfully")
    }
}