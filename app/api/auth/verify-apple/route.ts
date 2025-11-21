import { auth } from "@/lib/auth"
import { NextResponse } from "next/server"
import jwt from "jsonwebtoken"
import jwksClient from "jwks-rsa"
import { Pool } from "pg"

const client = jwksClient({
    jwksUri: "https://appleid.apple.com/auth/keys",
})

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
})

function getKey(header: any, callback: any) {
    client.getSigningKey(header.kid, function (err, key) {
        if (err) {
            callback(err, null)
            return
        }
        const signingKey = key?.getPublicKey()
        callback(null, signingKey)
    })
}

export async function POST(req: Request) {
    try {
        const body = await req.json()
        const { idToken, firstName, lastName } = body

        if (!idToken) {
            return NextResponse.json({ message: "Missing idToken" }, { status: 400 })
        }

        // 1. Verify Apple Token
        const decoded: any = await new Promise((resolve, reject) => {
            jwt.verify(idToken, getKey, {
                algorithms: ["RS256"],
                issuer: "https://appleid.apple.com",
                audience: process.env.NEXT_PUBLIC_APPLE_CLIENT_ID,
            }, (err, decoded) => {
                if (err) reject(err)
                else resolve(decoded)
            })
        })

        const email = decoded.email
        const sub = decoded.sub // Apple's unique user ID

        if (!email) {
            // If email is missing (subsequent logins), we need to find user by account link (sub)
            // For now, we'll return error if we can't find by email, but ideally we check 'account' table.
            // Let's check 'account' table for providerId = sub
        }

        // 2. Database Operations
        const db = await pool.connect()
        try {
            let user: any = null

            // Check if user exists by email
            if (email) {
                const res = await db.query("SELECT * FROM \"user\" WHERE email = $1", [email])
                if (res.rows.length > 0) {
                    user = res.rows[0]
                }
            }

            // If not found by email, check by provider account (sub)
            if (!user) {
                const res = await db.query("SELECT u.* FROM \"user\" u JOIN \"account\" a ON u.id = a.\"userId\" WHERE a.\"providerId\" = 'apple' AND a.\"accountId\" = $1", [sub])
                if (res.rows.length > 0) {
                    user = res.rows[0]
                }
            }

            // Create user if not exists
            if (!user) {
                if (!email) {
                    throw new Error("Email required for new user registration via Apple")
                }

                const newId = crypto.randomUUID()
                const now = new Date()
                const name = (firstName && lastName) ? `${firstName} ${lastName}` : "Apple User"

                // Insert user
                const insertRes = await db.query(
                    "INSERT INTO \"user\" (id, email, name, \"emailVerified\", \"createdAt\", \"updatedAt\", role, \"accountType\") VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *",
                    [newId, email, name, true, now, now, "student", "student"] // Default role
                )
                user = insertRes.rows[0]
            }

            // Ensure user is not null for TypeScript
            if (!user) {
                throw new Error("Failed to create or find user")
            }

            // Link account if not linked
            const accountRes = await db.query("SELECT * FROM \"account\" WHERE \"providerId\" = 'apple' AND \"accountId\" = $1", [sub])
            if (accountRes.rows.length === 0) {
                const accountId = crypto.randomUUID()
                const now = new Date()
                await db.query(
                    "INSERT INTO \"account\" (id, \"userId\", \"accountId\", \"providerId\", \"createdAt\", \"updatedAt\") VALUES ($1, $2, $3, $4, $5, $6)",
                    [accountId, user.id, sub, "apple", now, now]
                )
            }

            // 3. Create Session
            // We will use Better Auth's API if possible, but fallback to DB insert to be safe and sure.
            // Better Auth session table: id, userId, expiresAt, token, ipAddress, userAgent

            // Generate session token
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
        console.error("Apple verification error:", error)
        return NextResponse.json({ message: "Invalid token", error: error.message }, { status: 401 })
    }
}
