import { NextResponse } from "next/server"
import { google } from "googleapis"
import { Pool } from "pg"

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
})

const googleClient = new google.auth.OAuth2(
    process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID,
    process.env.GOOGLE_CLIENT_SECRET
)

export async function POST(req: Request) {
    try {
        const body = await req.json()
        const { idToken } = body

        if (!idToken) {
            return NextResponse.json({ message: "Missing idToken" }, { status: 400 })
        }

        // 1. Verify Google Token
        const ticket = await googleClient.verifyIdToken({
            idToken: idToken,
            audience: process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID,
        })

        const payload = ticket.getPayload()
        if (!payload) {
            throw new Error("Invalid token payload")
        }

        const email = payload.email
        const sub = payload.sub // Google's unique user ID
        const firstName = payload.given_name
        const lastName = payload.family_name
        const picture = payload.picture

        if (!email) {
            throw new Error("Email not found in token")
        }

        // 2. Database Operations
        const db = await pool.connect()
        try {
            let user: any = null

            // Check if user exists by email
            const res = await db.query("SELECT * FROM \"user\" WHERE email = $1", [email])
            if (res.rows.length > 0) {
                user = res.rows[0]
            }

            // If not found by email, check by provider account (sub)
            if (!user) {
                const res = await db.query("SELECT u.* FROM \"user\" u JOIN \"account\" a ON u.id = a.\"userId\" WHERE a.\"providerId\" = 'google' AND a.\"accountId\" = $1", [sub])
                if (res.rows.length > 0) {
                    user = res.rows[0]
                }
            }

            // Create user if not exists
            if (!user) {
                const newId = crypto.randomUUID()
                const now = new Date()
                const name = (firstName && lastName) ? `${firstName} ${lastName}` : "Google User"

                // Insert user
                const insertRes = await db.query(
                    "INSERT INTO \"user\" (id, email, name, \"emailVerified\", \"createdAt\", \"updatedAt\", role, \"accountType\", image) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *",
                    [newId, email, name, true, now, now, "student", "student", picture]
                )
                user = insertRes.rows[0]
            }

            if (!user) {
                throw new Error("Failed to create or find user")
            }

            // Link account if not linked
            const accountRes = await db.query("SELECT * FROM \"account\" WHERE \"providerId\" = 'google' AND \"accountId\" = $1", [sub])
            if (accountRes.rows.length === 0) {
                const accountId = crypto.randomUUID()
                const now = new Date()
                await db.query(
                    "INSERT INTO \"account\" (id, \"userId\", \"accountId\", \"providerId\", \"createdAt\", \"updatedAt\") VALUES ($1, $2, $3, $4, $5, $6)",
                    [accountId, user.id, sub, "google", now, now]
                )
            }

            // 3. Create Session
            const sessionToken = crypto.randomUUID()
            const sessionId = crypto.randomUUID()
            const expiresAt = new Date()
            expiresAt.setDate(expiresAt.getDate() + 7) // 7 days
            const now = new Date()

            await db.query(
                "INSERT INTO \"session\" (id, \"userId\", token, \"expiresAt\", \"createdAt\", \"updatedAt\") VALUES ($1, $2, $3, $4, $5, $6)",
                [sessionId, user.id, sessionToken, expiresAt, now, now]
            )

            return NextResponse.json({
                user: user,
                session: {
                    id: sessionId,
                    userId: user.id,
                    token: sessionToken,
                    expiresAt: expiresAt
                }
            })

        } finally {
            db.release()
        }

    } catch (error: any) {
        console.error("Google verification error:", error)
        return NextResponse.json({ message: "Invalid token", error: error.message }, { status: 401 })
    }
}
