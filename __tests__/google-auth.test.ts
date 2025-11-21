import { POST } from "../app/api/auth/verify-google/route"
import { NextResponse } from "next/server"

// Mock dependencies
jest.mock("googleapis", () => ({
    google: {
        auth: {
            OAuth2: jest.fn().mockImplementation(() => ({
                verifyIdToken: jest.fn().mockResolvedValue({
                    getPayload: () => ({
                        email: "test@example.com",
                        sub: "google_123",
                        given_name: "Jane",
                        family_name: "Doe",
                        picture: "http://example.com/pic.jpg"
                    })
                })
            }))
        }
    }
}))

jest.mock("pg", () => {
    const mPool = {
        connect: jest.fn(),
    }
    return { Pool: jest.fn(() => mPool) }
})

describe("Google Auth Endpoint", () => {
    let req: any
    let json: any

    beforeEach(() => {
        json = jest.fn()
        req = {
            json: jest.fn().mockResolvedValue({
                idToken: "mock_google_token"
            })
        }
    })

    it("should verify token and create session", async () => {
        // Mock DB
        const mClient = {
            query: jest.fn().mockResolvedValue({ rows: [] }),
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
    })
})
