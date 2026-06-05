const { GoogleAuth } = require('google-auth-library');
const serviceAccount = require('D:/IYF/sadhna/sadhana-app-iyf-firebase-adminsdk-fbsvc-3200344041.json');

const PROJECT_ID     = 'sadhana-app-iyf';
const ANDROID_APP_ID = '1:554264804185:android:284a37a9d92275bfc52a48';

async function main() {
  const auth = new GoogleAuth({ credentials: serviceAccount, scopes: ['https://www.googleapis.com/auth/firebase','https://www.googleapis.com/auth/cloud-platform'] });
  const client = await auth.getClient();

  // Use authClient.request() — handles URL encoding + auth header automatically
  const base = 'https://firebase.googleapis.com/v1beta1';
  const appPath = `projects/${PROJECT_ID}/androidApps/${ANDROID_APP_ID}`;

  // Try /getConfig
  try {
    const r = await client.request({ url: `${base}/${appPath}/getConfig`, method: 'GET' });
    console.log('✅ /getConfig status:', r.status);
    console.log('Keys:', Object.keys(r.data));
    console.log(JSON.stringify(r.data, null, 2).slice(0, 500));
  } catch (e) {
    console.log('❌ /getConfig error:', e.response?.status, JSON.stringify(e.response?.data || e.message).slice(0,200));
  }

  // Try :getConfig (colon style)
  try {
    const r = await client.request({ url: `${base}/${appPath}:getConfig`, method: 'GET' });
    console.log('\n✅ :getConfig status:', r.status);
    console.log(JSON.stringify(r.data, null, 2).slice(0, 500));
  } catch (e) {
    console.log('\n❌ :getConfig error:', e.response?.status, JSON.stringify(e.response?.data || e.message).slice(0,200));
  }
}
main().catch(console.error);
