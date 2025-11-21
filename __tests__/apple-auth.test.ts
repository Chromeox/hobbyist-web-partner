import { POST } from "../app/api/auth/verify-apple/route"
import { NextResponse } from "next/server"
import jwt from "jsonwebtoken"

// Mock dependencies
jest.mock("jsonwebtoken")
jest.mock("jwks-rsa", () => {
    return jest.fn().mockImplementation(() => ({
        getSigningKey: jest.fn((kid, cb) => cb(null, { getPublicKey: () => "mock_key" })),
    }))
})
jest.mock("pg", () => {
    const mPool = {
        connect: jest.fn(),
    }
    return { Pool: jest.fn(() => mPool) }
})

describe("Apple Auth Endpoint", () => {
    let req: any
    let json: any

    beforeEach(() => {
        json = jest.fn()
        req = {
            json: jest.fn().mockResolvedValue({
                idToken: "mock_token",
                firstName: "John",
                lastName: "Appleseed"
            })
        }

            // Mock jwt.verify to return success
            (jwt.verify as jest.Mock).mockImplementation((token, key, options, cb) => {
                cb(null, { email: "test@example.com", sub: "apple_123" })
            })
    })

    it("should verify token and create session", async () => {
        // Mock DB
        const mClient = {
            query: jest.fn().mockResolvedValue({ rows: [] }), // No user found initially
            release: jest.fn(),
        }
        const { Pool } = require("pg")
        Pool().connect.mockResolvedValue(mClient)

        // Mock insert returning user
        mClient.query
            .mockResolvedValueOnce({ rows: [] }) // Find by email
            .mockResolvedValueOnce({ rows: [] }) // Find by account
            .mockResolvedValueOnce({ rows: [{ id: "new_user_id", email: "test@example.com" }] }) // Insert user
            .mockResolvedValueOnce({ rows: [] }) // Check account
            .mockResolvedValueOnce({ rows: [] }) // Insert account
            .mockResolvedValueOnce({ rows: [] }) // Insert session

        const response = await POST(req)
        const data = await response.json()

        expect(response.status).toBe(200)
        expect(data.user).toBeDefined()
        expect(data.session).toBeDefined()
        expect(data.session.token).toBeDefined()
    })

    it("should handle invalid token", async () => {
        (jwt.verify as jest.Mock).mockImplementation((token, key, options, cb) => {
            cb(new Error("Invalid token"), null)
        })

        const response = await POST(req)
        const data = await response.json()

        expect(response.status).toBe(401)
        expect(data.message).toBe("Invalid token")
    })
})
