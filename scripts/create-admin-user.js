/**
 * Create Admin User Script
 *
 * This script creates an admin user with a password in the Better Auth database
 * Run with: node scripts/create-admin-user.js
 */

const bcrypt = require('bcrypt');
const { Pool } = require('pg');

// Configuration
const ADMIN_EMAIL = 'admin@hobbi.com';
const ADMIN_PASSWORD = 'AdminPassword123!'; // ⚠️ CHANGE THIS AFTER FIRST LOGIN!
const SALT_ROUNDS = 10;

async function createAdminUser() {
  // Connect to database
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
  });

  try {
    const client = await pool.connect();

    console.log('🔐 Hashing password...');
    const hashedPassword = await bcrypt.hash(ADMIN_PASSWORD, SALT_ROUNDS);

    console.log('👤 Creating/updating admin user...');

    // Create or update user
    const userResult = await client.query(`
      INSERT INTO "user" (email, "emailVerified", role, "accountType", "firstName", "lastName")
      VALUES ($1, true, 'admin', 'admin', 'Admin', 'User')
      ON CONFLICT (email)
      DO UPDATE SET
        "emailVerified" = true,
        role = 'admin',
        "accountType" = 'admin'
      RETURNING id, email, role
    `, [ADMIN_EMAIL]);

    const userId = userResult.rows[0].id;
    console.log(`✅ User created/updated:`, userResult.rows[0]);

    // Create or update password account
    await client.query(`
      INSERT INTO "account" ("userId", "accountId", "providerId", "password")
      VALUES ($1, $2, 'credential', $3)
      ON CONFLICT ("providerId", "accountId")
      DO UPDATE SET "password" = EXCLUDED."password"
    `, [userId, ADMIN_EMAIL, hashedPassword]);

    console.log('✅ Password account created/updated');

    // Verify
    const verifyResult = await client.query(`
      SELECT
        u.id,
        u.email,
        u.role,
        u."accountType",
        u."emailVerified",
        a."providerId",
        CASE WHEN a.password IS NOT NULL THEN '✅ Password Set' ELSE '❌ No Password' END as password_status
      FROM "user" u
      LEFT JOIN "account" a ON u.id = a."userId" AND a."providerId" = 'credential'
      WHERE u.email = $1
    `, [ADMIN_EMAIL]);

    console.log('\n📊 Admin User Status:');
    console.table(verifyResult.rows);

    console.log('\n🎉 Admin user setup complete!');
    console.log('\n📝 Login Credentials:');
    console.log(`   Email: ${ADMIN_EMAIL}`);
    console.log(`   Password: ${ADMIN_PASSWORD}`);
    console.log('\n⚠️  IMPORTANT: Change this password after first login!');

    client.release();
    await pool.end();

  } catch (error) {
    console.error('❌ Error:', error.message);
    await pool.end();
    process.exit(1);
  }
}

// Run the script
createAdminUser();
