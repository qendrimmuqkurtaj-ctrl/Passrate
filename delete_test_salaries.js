#!/usr/bin/env node
const https = require('https');

const PROJECT_ID = 'passrate-4360d';
const API_KEY    = 'AIzaSyAACELQ70qc3CbCAQm3XMASRZDR5f54j7A';
const BASE      = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

function req(method, path, extra = '') {
  return new Promise((resolve, reject) => {
    const url = `${BASE}${path}?key=${API_KEY}${extra}`;
    const parsed = new URL(url);
    const opts = {
      hostname: parsed.hostname,
      path: parsed.pathname + parsed.search,
      method,
    };
    const r = https.request(opts, (res) => {
      let data = '';
      res.on('data', d => data += d);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(data ? JSON.parse(data) : {});
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });
    r.on('error', reject);
    r.end();
  });
}

async function main() {
  console.log('Fetching salaries collection…\n');
  const res = await req('GET', '/salaries', '&pageSize=500');
  const docs = res.documents || [];

  const toDelete = docs.filter(doc => {
    const deviceId = doc.fields?.deviceId?.stringValue ?? '';
    return deviceId.startsWith('seed-') || deviceId.startsWith('test_device_');
  });

  console.log(`Total docs: ${docs.length}  |  Matching (to delete): ${toDelete.length}\n`);

  if (toDelete.length === 0) {
    console.log('Nothing to delete.');
    return;
  }

  for (const doc of toDelete) {
    const docId  = doc.name.split('/').pop();
    const device = doc.fields?.deviceId?.stringValue ?? '?';
    await req('DELETE', `/salaries/${docId}`);
    console.log(`  deleted  ${docId}  (${device})`);
  }

  console.log('\nDone.');
}

main().catch(console.error);
