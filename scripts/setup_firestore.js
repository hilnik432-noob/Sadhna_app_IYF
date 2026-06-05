/**
 * Firestore Setup Script — sadhana-app-iyf
 * Run: node setup_firestore.js
 *
 * Creates all collections with proper structure and seed data.
 * Only touches project: sadhana-app-iyf
 */

const admin = require('firebase-admin');
const serviceAccount = require('../../../sadhna/sadhana-app-iyf-firebase-adminsdk-fbsvc-3200344041.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'sadhana-app-iyf',
});

const db = admin.firestore();

// ─────────────────────────────────────────────
// Safety guard — abort if wrong project
// ─────────────────────────────────────────────
if (serviceAccount.project_id !== 'sadhana-app-iyf') {
  console.error('❌ Wrong project! Aborting.');
  process.exit(1);
}
console.log('✅ Connected to project: sadhana-app-iyf');

const now = admin.firestore.Timestamp.now();

// ─────────────────────────────────────────────
// COLLECTION 1: users
// One document per student. Created automatically on first Google login.
// Seeding one sample doc so the collection & schema are visible in console.
// ─────────────────────────────────────────────
async function setupUsers() {
  const ref = db.collection('users').doc('_schema_sample');
  await ref.set({
    uid:              '_schema_sample',
    name:             'Sample Student',
    email:            'student@example.com',
    phone:            '+91 98765 43210',
    photoUrl:         '',
    city:             'Mumbai',
    temple:           'ISKCON Mumbai',
    batch:            'Batch 2024',
    mentor:           'Mentor Name',
    role:             'student',          // student | mentor | admin
    joinedDate:       now,
    lastLoginAt:      now,
    lastSadhanaDate:  null,
    streakCount:      0,
    totalSadhanaLogs: 0,
    fcmToken:         '',
    isActive:         true,
    _note:            'Schema reference doc — safe to delete',
  });
  console.log('✅ users collection ready');
}

// ─────────────────────────────────────────────
// COLLECTION 2: users/{uid}/sadhana  (subcollection)
// One doc per student per day. dateKey = "YYYY-MM-DD".
// Seeding under the sample user.
// ─────────────────────────────────────────────
async function setupSadhanaSubcollection() {
  const ref = db
    .collection('users')
    .doc('_schema_sample')
    .collection('sadhana')
    .doc('2026-06-05');

  await ref.set({
    dateKey:        '2026-06-05',
    date:           now,
    userId:         '_schema_sample',
    userName:       'Sample Student',
    japaRounds:     16,
    mangalAarti:    true,
    morningProgram: true,
    readingMinutes: 30,
    wakeUpTime:     '4:30 AM',
    notes:          'Felt very focused today.',
    score:          95,              // computed: see SadhanaEntry.score
    createdAt:      now,
    updatedAt:      now,
  });
  console.log('✅ users/{uid}/sadhana subcollection ready');
}

// ─────────────────────────────────────────────
// COLLECTION 3: sadhana_logs  (top-level mirror)
// One doc per student per day. DocID = {uid}_{dateKey}
// Used for admin dashboards, leaderboards, batch reports.
// ─────────────────────────────────────────────
async function setupSadhanaLogs() {
  const ref = db.collection('sadhana_logs').doc('_schema_sample_2026-06-05');
  await ref.set({
    uid:            '_schema_sample',
    userName:       'Sample Student',
    dateKey:        '2026-06-05',
    date:           now,
    logId:          '2026-06-05',       // matching subcollection doc ID
    japaRounds:     16,
    mangalAarti:    true,
    morningProgram: true,
    readingMinutes: 30,
    wakeUpTime:     '4:30 AM',
    notes:          'Felt very focused today.',
    score:          95,
    createdAt:      now,
    updatedAt:      now,
    _note:          'Schema reference doc — safe to delete',
  });
  console.log('✅ sadhana_logs collection ready');
}

// ─────────────────────────────────────────────
// COLLECTION 4: events
// ─────────────────────────────────────────────
async function setupEvents() {
  const events = [
    {
      title:           'Janmashtami Mahotsav 2026',
      description:     "Grand celebration of Lord Krishna's appearance day with kirtan, drama, and prasad distribution.",
      startDate:       admin.firestore.Timestamp.fromDate(new Date('2026-08-16T06:00:00')),
      endDate:         admin.firestore.Timestamp.fromDate(new Date('2026-08-16T22:00:00')),
      location:        'ISKCON Temple, Mumbai',
      imageUrl:        '',
      liveStreamUrl:   '',
      isLive:          false,
      isFree:          true,
      registeredCount: 0,
      registeredUsers: [],   // array of UIDs
      createdAt:       now,
    },
    {
      title:           'Bhagavad Gita Study Camp',
      description:     'Intensive 7-day study of the Bhagavad Gita with senior devotees. Limited seats.',
      startDate:       admin.firestore.Timestamp.fromDate(new Date('2026-07-10T09:00:00')),
      endDate:         admin.firestore.Timestamp.fromDate(new Date('2026-07-17T18:00:00')),
      location:        'Govardhana Eco Village, Maharashtra',
      imageUrl:        '',
      liveStreamUrl:   '',
      isLive:          false,
      isFree:          false,
      registeredCount: 0,
      registeredUsers: [],
      createdAt:       now,
    },
    {
      title:           'Sunday Love Feast',
      description:     'Weekly program with kirtan, class, and sumptuous prasad. Open to all.',
      startDate:       admin.firestore.Timestamp.fromDate(new Date('2026-06-08T17:00:00')),
      endDate:         admin.firestore.Timestamp.fromDate(new Date('2026-06-08T20:00:00')),
      location:        'Local Temple',
      imageUrl:        '',
      liveStreamUrl:   '',
      isLive:          false,
      isFree:          true,
      registeredCount: 0,
      registeredUsers: [],
      createdAt:       now,
    },
  ];

  const batch = db.batch();
  for (const event of events) {
    batch.set(db.collection('events').doc(), event);
  }
  await batch.commit();
  console.log(`✅ events collection ready (${events.length} events)`);
}

// ─────────────────────────────────────────────
// COLLECTION 5: content
// Lectures, kirtans, books added by admin via Firebase console.
// ─────────────────────────────────────────────
async function setupContent() {
  const items = [
    {
      title:           'Introduction to Bhakti Yoga',
      subtitle:        'HH Radhanath Swami',
      type:            'lecture',          // lecture | kirtan | book
      contentUrl:      'https://www.youtube.com/watch?v=example1',
      thumbnailUrl:    '',
      description:     'A beautiful introduction to the path of devotion.',
      durationSeconds: 3600,
      views:           0,
      createdAt:       now,
    },
    {
      title:           'Hare Krishna Maha Mantra Kirtan',
      subtitle:        'ISKCON',
      type:            'kirtan',
      contentUrl:      'https://www.youtube.com/watch?v=example2',
      thumbnailUrl:    '',
      description:     'Melodious kirtan for morning meditation.',
      durationSeconds: 1800,
      views:           0,
      createdAt:       now,
    },
    {
      title:           'Bhagavad Gita As It Is',
      subtitle:        'A.C. Bhaktivedanta Swami Prabhupada',
      type:            'book',
      contentUrl:      'https://asitis.com',
      thumbnailUrl:    '',
      description:     'The complete Bhagavad Gita with purports.',
      durationSeconds: 0,
      views:           0,
      createdAt:       now,
    },
  ];

  const batch = db.batch();
  for (const item of items) {
    batch.set(db.collection('content').doc(), item);
  }
  await batch.commit();
  console.log(`✅ content collection ready (${items.length} items)`);
}

// ─────────────────────────────────────────────
// COLLECTION 6: announcements
// Push notification content stored here for reference.
// ─────────────────────────────────────────────
async function setupAnnouncements() {
  await db.collection('announcements').doc('welcome').set({
    title:     'Welcome to Sadhana App!',
    body:      'Start logging your daily sadhana and build your streak. Hare Krishna! 🙏',
    imageUrl:  '',
    targetAll: true,
    createdAt: now,
    sentAt:    null,
  });
  console.log('✅ announcements collection ready');
}

// ─────────────────────────────────────────────
// RUN ALL
// ─────────────────────────────────────────────
async function main() {
  console.log('\n📦 Setting up Firestore collections for sadhana-app-iyf...\n');
  try {
    await setupUsers();
    await setupSadhanaSubcollection();
    await setupSadhanaLogs();
    await setupEvents();
    await setupContent();
    await setupAnnouncements();

    console.log('\n✅ All collections created successfully!\n');
    console.log('Collections created:');
    console.log('  • users               — student profiles');
    console.log('  • users/{uid}/sadhana — daily sadhana logs per student');
    console.log('  • sadhana_logs        — top-level mirror for admin tracking');
    console.log('  • events              — events & live streams');
    console.log('  • content             — lectures, kirtans, books');
    console.log('  • announcements       — push notification records');
    console.log('\nYou can safely delete the _schema_sample docs from the console.');
  } catch (err) {
    console.error('❌ Error:', err.message);
  }
  process.exit(0);
}

main();
