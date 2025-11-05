#!/usr/bin/env node

/**
 * Partner Dashboard Regression Check
 *
 * Exercises critical partner dashboard flows against the live Supabase API:
 * - Pricing (credit packs + studio payment settings)
 * - Classes (class schedules + class metadata)
 * - Payouts (bookings + payout history coverage)
 * - Messages (conversations + messages integrity)
 * - Reviews (recent review data health)
 *
 * Outputs a Markdown report under ../test-results with pass/warn/fail status.
 */

const fs = require('fs');
const path = require('path');
const { createClient } = require('@supabase/supabase-js');
const dotenvPath = path.resolve(__dirname, '..', '.env.local');

require('dotenv').config({ path: dotenvPath });

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('❌ Missing Supabase credentials. Ensure NEXT_PUBLIC_SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are set in web-partner/.env.local');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

const STATUS = {
  PASS: 'PASS',
  WARN: 'WARN',
  FAIL: 'FAIL',
};

const report = [];

const formatCurrency = (valueCents) => {
  if (typeof valueCents !== 'number' || Number.isNaN(valueCents)) return 'n/a';
  return `$${(valueCents / 100).toFixed(2)}`;
};

function record(area, status, message, details = null) {
  report.push({ area, status, message, details });
  const prefix = status === STATUS.FAIL ? '❌' : status === STATUS.WARN ? '⚠️ ' : '✅';
  console.log(`${prefix} [${area}] ${message}`);
  if (details) {
    console.log(`    ↳ ${details}`);
  }
}

async function checkPricing() {
  const area = 'Pricing';

  try {
    const { data: packs, error: packsError } = await supabase
      .from('credit_packs')
      .select('*')
      .order('display_order', { ascending: true })
      .limit(25);

    if (packsError) {
      record(area, STATUS.FAIL, 'Failed to load credit packs', packsError.message);
    } else if (!packs || packs.length === 0) {
      record(area, STATUS.WARN, 'No credit packs returned from API');
    } else {
      const invalid = packs.filter(
        (pack) =>
          typeof pack.credit_amount !== 'number' ||
          pack.credit_amount <= 0 ||
          typeof pack.price_cents !== 'number' ||
          pack.price_cents <= 0
      );

      if (invalid.length > 0) {
        const samples = invalid
          .slice(0, 3)
          .map(
            (pack) =>
              `${pack.name ?? pack.id} (credits=${pack.credit_amount}, price=${formatCurrency(pack.price_cents ?? NaN)})`
          )
          .join('; ');
        record(
          area,
          STATUS.FAIL,
          'Credit packs returned with invalid credit_amount or price_cents values',
          samples
        );
      } else {
        record(
          area,
          STATUS.PASS,
          `Loaded ${packs.length} credit packs; sample ${packs[0].name ?? packs[0].id} priced at ${formatCurrency(
            packs[0].price_cents
          )}`
        );
      }
    }

    const { data: settings, error: settingsError } = await supabase
      .from('studio_payment_settings')
      .select('studio_id, commission_rate, minimum_payout_cents, payout_frequency, updated_at')
      .limit(1);

    if (settingsError) {
      record(area, STATUS.FAIL, 'Failed to load studio payment settings', settingsError.message);
    } else if (!settings || settings.length === 0) {
      record(area, STATUS.WARN, 'No studio_payment_settings rows found (defaults will be used)');
    } else {
      const config = settings[0];
      const validCommission =
        typeof config.commission_rate === 'number' &&
        config.commission_rate >= 0 &&
        config.commission_rate <= 1;
      const validMinimum =
        typeof config.minimum_payout_cents === 'number' && config.minimum_payout_cents >= 0;
      const validFrequency = ['daily', 'weekly', 'monthly'].includes(config.payout_frequency);

      if (validCommission && validMinimum && validFrequency) {
        record(
          area,
          STATUS.PASS,
          `Studio payment settings valid (commission ${Math.round(config.commission_rate * 100)}%, minimum ${formatCurrency(
            config.minimum_payout_cents ?? 0
          )}, ${config.payout_frequency})`
        );
      } else {
        record(
          area,
          STATUS.FAIL,
          'Invalid studio payment settings detected',
          JSON.stringify(config)
        );
      }
    }
  } catch (error) {
    record(area, STATUS.FAIL, 'Unexpected error during pricing checks', error.message);
  }
}

async function checkClasses() {
  const area = 'Classes';

  try {
    const { data: schedules, error: scheduleError } = await supabase
      .from('class_schedules')
      .select(
        `
        id,
        class_id,
        start_time,
        end_time,
        is_cancelled,
        classes:classes!inner (
          id,
          name,
          is_active,
          price
        )
      `
      )
      .order('start_time', { ascending: true })
      .limit(25);

    if (scheduleError) {
      record(area, STATUS.FAIL, 'Failed to load class schedules', scheduleError.message);
    } else if (!schedules || schedules.length === 0) {
      record(area, STATUS.WARN, 'No upcoming class schedules returned');
    } else {
      const missingClasses = schedules.filter((schedule) => !schedule.classes);
      const inactiveClasses = schedules.filter(
        (schedule) => schedule.classes && schedule.classes.is_active === false
      );

      if (missingClasses.length > 0) {
        record(
          area,
          STATUS.FAIL,
          'Class schedules returned without related class metadata',
          `Examples: ${missingClasses
            .slice(0, 3)
            .map((s) => `${s.id} (class_id=${s.class_id})`)
            .join(', ')}`
        );
      } else {
        record(
          area,
          STATUS.PASS,
          `Loaded ${schedules.length} class schedules with class metadata`
        );
      }

      if (inactiveClasses.length > 0) {
        record(
          area,
          STATUS.WARN,
          `${inactiveClasses.length} schedules reference inactive classes`,
          inactiveClasses
            .slice(0, 3)
            .map((s) => `${s.classes?.name ?? s.class_id} (${s.class_id})`)
            .join('; ')
        );
      }
    }
  } catch (error) {
    record(area, STATUS.FAIL, 'Unexpected error during class checks', error.message);
  }
}

async function checkPayouts() {
  const area = 'Payouts';

  try {
    const { data: bookings, error: bookingsError } = await supabase
      .from('bookings')
      .select('*')
      .eq('status', 'completed')
      .order('created_at', { ascending: false })
      .limit(25);

    if (bookingsError) {
      record(area, STATUS.FAIL, 'Failed to load completed bookings', bookingsError.message);
    } else if (!bookings || bookings.length === 0) {
      record(area, STATUS.WARN, 'No completed bookings available to validate payouts');
    } else {
      const missingFinancials = bookings.filter(
        (booking) =>
          typeof booking.amount !== 'number' ||
          typeof booking.commission_amount !== 'number' ||
          typeof booking.instructor_payout !== 'number'
      );

      if (missingFinancials.length > 0) {
        record(
          area,
          STATUS.FAIL,
          'Completed bookings missing amount/commission/payout fields',
          missingFinancials
            .slice(0, 3)
            .map((b) => `${b.id} (amount=${b.amount}, commission=${b.commission_amount}, payout=${b.instructor_payout})`)
            .join('; ')
        );
      } else {
        const sample = bookings[0];
        record(
          area,
          STATUS.PASS,
          `Validated ${bookings.length} completed bookings with financial fields present (sample payout ${sample.instructor_payout})`
        );
      }
    }

    const { data: payoutHistory, error: historyError } = await supabase
      .from('payout_history')
      .select('*')
      .order('payout_date', { ascending: false })
      .limit(10);

    if (historyError) {
      record(area, STATUS.FAIL, 'Failed to load payout history', historyError.message);
    } else if (!payoutHistory || payoutHistory.length === 0) {
      record(area, STATUS.WARN, 'No payout history records found');
    } else {
      const failures = payoutHistory.filter((row) => row.status === 'failed');
      if (failures.length > 0) {
        record(
          area,
          STATUS.WARN,
          `${failures.length} payout_history entries marked failed`,
          failures
            .slice(0, 3)
            .map((f) => `${f.instructor_id} (${f.error_message ?? 'no error detail'})`)
            .join('; ')
        );
      } else {
        record(
          area,
          STATUS.PASS,
          `Payout history healthy (${payoutHistory.length} recent records, no failures)`
        );
      }
    }
  } catch (error) {
    record(area, STATUS.FAIL, 'Unexpected error during payout checks', error.message);
  }
}

async function checkMessages() {
  const area = 'Messages';

  try {
    const { data: conversations, error: convError } = await supabase
      .from('conversations')
      .select('*')
      .order('updated_at', { ascending: false })
      .limit(20);

    if (convError) {
      record(area, STATUS.FAIL, 'Failed to load conversations', convError.message);
    } else if (!conversations || conversations.length === 0) {
      record(area, STATUS.WARN, 'No conversations found');
    } else {
      const invalidParticipants = conversations.filter(
        (conversation) => !Array.isArray(conversation.participants) || conversation.participants.length === 0
      );

      if (invalidParticipants.length > 0) {
        record(
          area,
          STATUS.FAIL,
          'Conversations returned without participant IDs',
          invalidParticipants
            .slice(0, 3)
            .map((c) => `${c.id} (${c.name})`)
            .join('; ')
        );
      } else {
        record(
          area,
          STATUS.PASS,
          `Loaded ${conversations.length} conversations (sample "${conversations[0].name}")`
        );
      }
    }

    const { data: messages, error: msgError } = await supabase
      .from('messages')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(20);

    if (msgError) {
      record(area, STATUS.FAIL, 'Failed to load messages', msgError.message);
    } else if (!messages || messages.length === 0) {
      record(area, STATUS.WARN, 'No messages found');
    } else {
      const emptyMessages = messages.filter(
        (message) => !message.content || message.content.trim().length === 0
      );

      if (emptyMessages.length > 0) {
        record(
          area,
          STATUS.FAIL,
          'Messages returned without content',
          emptyMessages
            .slice(0, 3)
            .map((m) => `${m.id} (conversation=${m.conversation_id})`)
            .join('; ')
        );
      } else {
        record(
          area,
          STATUS.PASS,
          `Loaded ${messages.length} messages with content (latest "${messages[0].content.slice(
            0,
            40
          )}...")`
        );
      }
    }
  } catch (error) {
    record(area, STATUS.FAIL, 'Unexpected error during messaging checks', error.message);
  }
}

async function checkReviews() {
  const area = 'Reviews';

  try {
    const { data: reviews, error: reviewsError } = await supabase
      .from('reviews')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(20);

    if (reviewsError) {
      record(area, STATUS.FAIL, 'Failed to load reviews', reviewsError.message);
    } else if (!reviews || reviews.length === 0) {
      record(area, STATUS.WARN, 'No reviews found');
    } else {
      const invalidRatings = reviews.filter(
        (review) =>
          typeof review.rating !== 'number' || review.rating < 1 || review.rating > 5
      );

      if (invalidRatings.length > 0) {
        record(
          area,
          STATUS.FAIL,
          'Reviews returned with out-of-range rating values',
          invalidRatings
            .slice(0, 3)
            .map((r) => `${r.id} (rating=${r.rating})`)
            .join('; ')
        );
      } else {
        record(
          area,
          STATUS.PASS,
          `Loaded ${reviews.length} reviews with valid ratings (latest rating ${reviews[0].rating})`
        );
      }
    }
  } catch (error) {
    record(area, STATUS.FAIL, 'Unexpected error during review checks', error.message);
  }
}

async function main() {
  console.log('🚦 Running Partner Dashboard regression checks...\n');

  await checkPricing();
  await checkClasses();
  await checkPayouts();
  await checkMessages();
  await checkReviews();

  const overall =
    report.some((entry) => entry.status === STATUS.FAIL)
      ? STATUS.FAIL
      : report.some((entry) => entry.status === STATUS.WARN)
      ? STATUS.WARN
      : STATUS.PASS;

  const timestamp = new Date();
  const iso = timestamp.toISOString();
  const safeStamp = iso.replace(/[:]/g, '-');
  const logDir = path.resolve(__dirname, '..', 'test-results');
  const logPath = path.join(logDir, `partner-dashboard-regression-${safeStamp}.md`);

  const grouped = report.reduce((acc, entry) => {
    if (!acc[entry.area]) acc[entry.area] = [];
    acc[entry.area].push(entry);
    return acc;
  }, {});

  const markdownLines = [
    `# Partner Dashboard Regression Report`,
    ``,
    `- Generated: ${iso}`,
    `- Supabase URL: ${supabaseUrl}`,
    `- Overall Status: ${overall}`,
    ``,
  ];

  for (const area of Object.keys(grouped)) {
    markdownLines.push(`## ${area}`);
    grouped[area].forEach((entry) => {
      const detail = entry.details ? ` — ${entry.details}` : '';
      markdownLines.push(`- **${entry.status}** ${entry.message}${detail}`);
    });
    markdownLines.push('');
  }

  fs.mkdirSync(logDir, { recursive: true });
  fs.writeFileSync(logPath, markdownLines.join('\n'));

  console.log('\n📝 Regression report written to:');
  console.log(`   ${logPath}`);
  console.log(`\nOverall status: ${overall}`);

  if (overall === STATUS.FAIL) {
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error('💥 Regression check failed:', error);
  process.exit(1);
});

