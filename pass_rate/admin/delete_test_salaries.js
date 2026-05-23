// Delete all salary documents where deviceId starts with "test_"
// Run: node admin/delete_test_salaries.js

const PROJECT_ID = 'passrate-4360d';
const API_KEY = 'AIzaSyBSUf-E1Z9GMzkeDYhu68HRXpeEhDV9alg';
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

async function queryTestSalaries() {
  const url = `${BASE_URL}:runQuery?key=${API_KEY}`;
  const body = JSON.stringify({
    structuredQuery: {
      from: [{ collectionId: 'salaries' }],
      where: {
        fieldFilter: {
          field: { fieldPath: 'deviceId' },
          op: 'GREATER_THAN_OR_EQUAL',
          value: { stringValue: 'test_' },
        },
      },
    },
  });
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body,
  });
  if (!res.ok) throw new Error(`Query failed: HTTP ${res.status}: ${await res.text()}`);
  const rows = await res.json();
  return rows
    .filter(r => r.document)
    .filter(r => {
      const deviceId = r.document.fields?.deviceId?.stringValue ?? '';
      return deviceId.startsWith('test_');
    })
    .map(r => r.document.name);
}

async function deleteDocument(name) {
  const url = `https://firestore.googleapis.com/v1/${name}?key=${API_KEY}`;
  const res = await fetch(url, { method: 'DELETE' });
  if (!res.ok) throw new Error(`Delete failed: HTTP ${res.status}: ${await res.text()}`);
}

async function main() {
  console.log('Querying test salary documents...');
  const names = await queryTestSalaries();
  if (names.length === 0) {
    console.log('No test documents found.');
    return;
  }
  console.log(`Found ${names.length} test document(s). Deleting...`);
  let ok = 0;
  let fail = 0;
  for (const name of names) {
    const id = name.split('/').pop();
    try {
      await deleteDocument(name);
      console.log(`✓ Deleted ${id}`);
      ok++;
    } catch (e) {
      console.error(`✗ ${id}: ${e.message}`);
      fail++;
    }
  }
  console.log(`\nDone: ${ok} deleted, ${fail} failed.`);
}

main();
