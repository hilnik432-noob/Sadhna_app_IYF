/**
 * connect_firebase.js
 * Registers Android + Web apps in sadhana-app-iyf,
 * downloads google-services.json and generates firebase_options.dart
 *
 * Run: node connect_firebase.js
 */

const admin   = require('firebase-admin');
const axios   = require('axios');
const fs      = require('fs');
const path    = require('path');

const serviceAccount = require('../../../sadhna/sadhana-app-iyf-firebase-adminsdk-fbsvc-3200344041.json');

// Safety guard
if (serviceAccount.project_id !== 'sadhana-app-iyf') {
  console.error('❌ Wrong project! Aborting.'); process.exit(1);
}

const PROJECT_ID   = 'sadhana-app-iyf';
const ANDROID_PKG  = 'com.iyf.sadhana_app';
const APP_NAME     = 'Sadhana App';
const BASE_URL     = 'https://firebase.googleapis.com';

// ── get OAuth2 access token via service account ───────────────────────────
async function getAccessToken() {
  const { GoogleAuth } = require('google-auth-library');
  const auth = new GoogleAuth({
    credentials: serviceAccount,
    scopes: ['https://www.googleapis.com/auth/firebase', 'https://www.googleapis.com/auth/cloud-platform'],
  });
  const client = await auth.getClient();
  const token  = await client.getAccessToken();
  return token.token;
}

// ── generic REST helper ───────────────────────────────────────────────────
async function restCall(method, urlPath, token, body = null) {
  const url = `https://firebase.googleapis.com${urlPath}`;
  const res = await axios({ method, url, headers: { Authorization: `Bearer ${token}` }, data: body || undefined, validateStatus: () => true });
  return { status: res.status, data: res.data };
}

// ── wait for long-running operation ──────────────────────────────────────
async function waitForOperation(opName, token) {
  for (let i = 0; i < 20; i++) {
    await new Promise(r => setTimeout(r, 3000));
    const res = await restCall('GET', `/v1/${opName}`, token);
    if (res.data.done) return res.data.response;
    process.stdout.write('.');
  }
  throw new Error('Operation timed out');
}

// ── Android app ───────────────────────────────────────────────────────────
async function ensureAndroidApp(token) {
  // List existing
  const list = await restCall('GET', `/v1beta1/projects/${PROJECT_ID}/androidApps`, token);
  const apps = list.data.apps || [];
  const existing = apps.find(a => a.packageName === ANDROID_PKG);
  if (existing) {
    console.log(`✅ Android app already exists: ${existing.appId}`);
    return existing.appId;
  }

  // Create
  console.log('📱 Creating Android app...');
  const create = await restCall('POST', `/v1beta1/projects/${PROJECT_ID}/androidApps`, token, {
    packageName:  ANDROID_PKG,
    displayName:  APP_NAME,
  });

  if (create.data.name) {
    process.stdout.write('   Waiting');
    const result = await waitForOperation(create.data.name.replace(/^operations\//, 'operations/'), token);
    console.log(`\n✅ Android app created: ${result?.appId || 'done'}`);
    // Re-fetch to get appId
    const list2 = await restCall('GET', `/v1beta1/projects/${PROJECT_ID}/androidApps`, token);
    const app2 = (list2.data.apps || []).find(a => a.packageName === ANDROID_PKG);
    return app2?.appId;
  }
  return create.data.appId;
}

// ── google-services.json ──────────────────────────────────────────────────
async function downloadGoogleServicesJson(appId, token) {
  const res = await restCall('GET', `/v1beta1/projects/${PROJECT_ID}/androidApps/${appId}/getConfig`, token);
  if (res.status !== 200) throw new Error(`Failed to get Android config: ${JSON.stringify(res.data)}`);

  const jsonContent = Buffer.from(res.data.configFileContents, 'base64').toString('utf-8');
  const destPath = path.resolve(__dirname, '..', 'android', 'app', 'google-services.json');
  fs.writeFileSync(destPath, jsonContent);
  console.log(`✅ google-services.json saved to android/app/`);
  return JSON.parse(jsonContent);
}

// ── Web app ───────────────────────────────────────────────────────────────
async function ensureWebApp(token) {
  const list = await restCall('GET', `/v1beta1/projects/${PROJECT_ID}/webApps`, token);
  const apps = list.data.apps || [];
  if (apps.length > 0) {
    console.log(`✅ Web app already exists: ${apps[0].appId}`);
    return apps[0].appId;
  }

  console.log('🌐 Creating Web app...');
  const create = await restCall('POST', `/v1beta1/projects/${PROJECT_ID}/webApps`, token, {
    displayName: APP_NAME,
  });

  if (create.data.name) {
    process.stdout.write('   Waiting');
    const result = await waitForOperation(create.data.name.replace(/^operations\//, 'operations/'), token);
    console.log(`\n✅ Web app created`);
    const list2 = await restCall('GET', `/v1beta1/projects/${PROJECT_ID}/webApps`, token);
    return (list2.data.apps || [])[0]?.appId;
  }
  return create.data.appId;
}

// ── Web app config ────────────────────────────────────────────────────────
async function getWebConfig(appId, token) {
  const encodedId = encodeURIComponent(appId);
  const res = await restCall('GET', `/v1beta1/projects/${PROJECT_ID}/webApps/${encodedId}/getConfig`, token);
  if (res.status !== 200) throw new Error(`Failed to get Web config: ${JSON.stringify(res.data)}`);
  console.log('✅ Web config fetched');
  return res.data;
}

// ── generate firebase_options.dart ────────────────────────────────────────
function generateFirebaseOptions(webCfg, googleServices) {
  // Extract android values from google-services.json
  const androidClient = googleServices.client?.[0];
  const androidApiKey = androidClient?.api_key?.[0]?.current_key || '';
  const androidAppId  = androidClient?.client_info?.mobilesdk_app_id || '';
  const senderId      = googleServices.project_info?.project_number || '';
  const projectId     = googleServices.project_info?.project_id || PROJECT_ID;
  const storageBucket = googleServices.project_info?.storage_bucket || `${PROJECT_ID}.appspot.com`;

  const dart = `// Generated by connect_firebase.js — DO NOT edit manually
// Project: sadhana-app-iyf

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            '${webCfg.apiKey}',
    appId:             '${webCfg.appId}',
    messagingSenderId: '${webCfg.messagingSenderId}',
    projectId:         '${webCfg.projectId}',
    authDomain:        '${webCfg.authDomain}',
    storageBucket:     '${webCfg.storageBucket}',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            '${androidApiKey}',
    appId:             '${androidAppId}',
    messagingSenderId: '${senderId}',
    projectId:         '${projectId}',
    storageBucket:     '${storageBucket}',
  );

  // iOS: add an iOS app in Firebase Console and fill these in
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'YOUR_IOS_API_KEY',
    appId:             'YOUR_IOS_APP_ID',
    messagingSenderId: '${senderId}',
    projectId:         '${projectId}',
    storageBucket:     '${storageBucket}',
    iosBundleId:       'com.iyf.sadhanaApp',
  );
}
`;

  const destPath = path.resolve(__dirname, '..', 'lib', 'firebase_options.dart');
  fs.writeFileSync(destPath, dart);
  console.log('✅ lib/firebase_options.dart generated with real credentials');
}

// ── main ──────────────────────────────────────────────────────────────────
async function main() {
  console.log('\n🔗 Connecting sadhana_app to Firebase project: sadhana-app-iyf\n');
  try {
    const token        = await getAccessToken();

    const androidAppId = await ensureAndroidApp(token);
    const googleSvc    = await downloadGoogleServicesJson(androidAppId, token);

    const webAppId     = await ensureWebApp(token);
    const webCfg       = await getWebConfig(webAppId, token);

    generateFirebaseOptions(webCfg, googleSvc);

    console.log('\n✅ Firebase connection complete!\n');
    console.log('Files written:');
    console.log('  • android/app/google-services.json');
    console.log('  • lib/firebase_options.dart');
    console.log('\nNext: flutter run -d chrome');
  } catch (err) {
    console.error('\n❌ Error:', err.message);
    process.exit(1);
  }
}

main();
