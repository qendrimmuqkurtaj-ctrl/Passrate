// Seed 30 test salary submissions to Firestore
// Run: node admin/seed_salaries.js

const PROJECT_ID = 'passrate-4360d';
const API_KEY = 'AIzaSyBSUf-E1Z9GMzkeDYhu68HRXpeEhDV9alg';
const BASE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/salaries`;

const submissions = [
  // ── SAS FO A320 Norway — 5+ matching "Pilots like me" (FO, A320, gross, seniority 1±2) ──
  {
    deviceId: 'test_sas_fo_no_01',
    airlineId: 'sas',
    airline: 'SAS',
    rank: 'FO',
    seniorityYears: 1,
    aircraftType: 'A320',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 55000,
    allInMonthlyEstimate: 68000,
    country: 'Norway',
    base: 'Oslo',
    currency: 'NOK',
    amountType: 'Gross (before tax)',
  },
  {
    deviceId: 'test_sas_fo_no_02',
    airlineId: 'sas',
    airline: 'SAS',
    rank: 'FO',
    seniorityYears: 2,
    aircraftType: 'A320',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 57500,
    allInMonthlyEstimate: 71000,
    country: 'Norway',
    base: 'Oslo',
    currency: 'NOK',
    amountType: 'Gross (before tax)',
  },
  {
    deviceId: 'test_sas_fo_no_03',
    airlineId: 'sas',
    airline: 'SAS',
    rank: 'FO',
    seniorityYears: 3,
    aircraftType: 'A320',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 60000,
    country: 'Norway',
    base: 'Bergen',
    currency: 'NOK',
    amountType: 'Gross (before tax)',
  },
  {
    deviceId: 'test_sas_fo_no_04',
    airlineId: 'sas',
    airline: 'SAS',
    rank: 'FO',
    seniorityYears: 1,
    aircraftType: 'A320',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 54000,
    allInMonthlyEstimate: 66000,
    country: 'Norway',
    base: 'Stavanger',
    currency: 'NOK',
    amountType: 'Gross (before tax)',
  },
  {
    deviceId: 'test_sas_fo_no_05',
    airlineId: 'sas',
    airline: 'SAS',
    rank: 'FO',
    seniorityYears: 2,
    aircraftType: 'A320',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 58000,
    country: 'Norway',
    base: 'Trondheim',
    currency: 'NOK',
    amountType: 'Gross (before tax)',
  },
  {
    deviceId: 'test_sas_fo_no_06',
    airlineId: 'sas',
    airline: 'SAS',
    rank: 'FO',
    seniorityYears: 3,
    aircraftType: 'A320',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 61000,
    allInMonthlyEstimate: 75000,
    country: 'Norway',
    base: 'Oslo',
    currency: 'NOK',
    amountType: 'Gross (before tax)',
  },

  // ── Ryanair FO 737-800 Ireland (gross, seniority only) ──
  {
    deviceId: 'test_ryanair_fo_ie_01',
    airlineId: 'ryanair',
    airline: 'Ryanair',
    rank: 'FO',
    seniorityYears: 5,
    aircraftType: '737-800',
    contractType: 'Contractor',
    guaranteedMonthlyPay: 5500,
    allInMonthlyEstimate: 7200,
    country: 'Ireland',
    base: 'Dublin',
    currency: 'EUR',
    amountType: 'Gross (before tax)',
  },
  {
    deviceId: 'test_ryanair_fo_ie_02',
    airlineId: 'ryanair',
    airline: 'Ryanair',
    rank: 'FO',
    seniorityYears: 7,
    aircraftType: '737-800',
    contractType: 'Contractor',
    guaranteedMonthlyPay: 6000,
    allInMonthlyEstimate: 7800,
    country: 'Ireland',
    base: 'Dublin',
    currency: 'EUR',
    amountType: 'Gross (before tax)',
  },
  {
    deviceId: 'test_ryanair_fo_ie_03',
    airlineId: 'ryanair',
    airline: 'Ryanair',
    rank: 'FO',
    seniorityYears: 3,
    aircraftType: '737-800',
    contractType: 'Contractor',
    guaranteedMonthlyPay: 5200,
    country: 'Ireland',
    base: 'Dublin',
    currency: 'EUR',
    amountType: 'Gross (before tax)',
  },

  // ── British Airways Captain 777 UK (gross, seniority only) ──
  {
    deviceId: 'test_ba_cap_gb_01',
    airlineId: 'british_airways',
    airline: 'British Airways',
    rank: 'Captain',
    seniorityYears: 15,
    aircraftType: '777',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 12000,
    allInMonthlyEstimate: 15500,
    country: 'UK',
    base: 'London',
    currency: 'GBP',
    amountType: 'Gross (before tax)',
  },
  {
    deviceId: 'test_ba_cap_gb_02',
    airlineId: 'british_airways',
    airline: 'British Airways',
    rank: 'Captain',
    seniorityYears: 18,
    aircraftType: '777',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 13500,
    country: 'UK',
    base: 'London',
    currency: 'GBP',
    amountType: 'Gross (before tax)',
  },
  {
    deviceId: 'test_ba_cap_gb_03',
    airlineId: 'british_airways',
    airline: 'British Airways',
    rank: 'Captain',
    seniorityYears: 12,
    aircraftType: '777',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 11500,
    allInMonthlyEstimate: 14800,
    country: 'UK',
    base: 'London',
    currency: 'GBP',
    amountType: 'Gross (before tax)',
  },

  // ── Norwegian Captain 737-800 Norway (gross, both seniority and hours) ──
  {
    deviceId: 'test_norwegian_cap_no_01',
    airlineId: 'norwegian',
    airline: 'Norwegian',
    rank: 'Captain',
    seniorityYears: 10,
    totalFlightHours: 9500,
    aircraftType: '737-800',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 100000,
    allInMonthlyEstimate: 125000,
    country: 'Norway',
    base: 'Oslo',
    currency: 'NOK',
    amountType: 'Gross (before tax)',
  },
  {
    deviceId: 'test_norwegian_cap_no_02',
    airlineId: 'norwegian',
    airline: 'Norwegian',
    rank: 'Captain',
    seniorityYears: 8,
    totalFlightHours: 7800,
    aircraftType: '737-800',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 95000,
    country: 'Norway',
    base: 'Oslo',
    currency: 'NOK',
    amountType: 'Gross (before tax)',
  },
  {
    deviceId: 'test_norwegian_cap_no_03',
    airlineId: 'norwegian',
    airline: 'Norwegian',
    rank: 'Captain',
    seniorityYears: 12,
    totalFlightHours: 11200,
    aircraftType: '737-800',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 110000,
    allInMonthlyEstimate: 138000,
    country: 'Norway',
    base: 'Bergen',
    currency: 'NOK',
    amountType: 'Gross (before tax)',
  },

  // ── easyJet SO A320 UK (flight hours only) ──
  {
    deviceId: 'test_easyjet_so_gb_01',
    airlineId: 'easyjet',
    airline: 'easyJet',
    rank: 'SO',
    seniorityYears: 0,
    totalFlightHours: 800,
    aircraftType: 'A320',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 3500,
    country: 'UK',
    base: 'London',
    currency: 'GBP',
    amountType: 'Gross (before tax)',
  },
  {
    deviceId: 'test_easyjet_so_gb_02',
    airlineId: 'easyjet',
    airline: 'easyJet',
    rank: 'SO',
    seniorityYears: 0,
    totalFlightHours: 1200,
    aircraftType: 'A320',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 3800,
    country: 'UK',
    base: 'Manchester',
    currency: 'GBP',
    amountType: 'Gross (before tax)',
  },
  {
    deviceId: 'test_easyjet_so_gb_03',
    airlineId: 'easyjet',
    airline: 'easyJet',
    rank: 'SO',
    seniorityYears: 1,
    aircraftType: 'A320',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 4000,
    allInMonthlyEstimate: 4600,
    country: 'UK',
    base: 'London',
    currency: 'GBP',
    amountType: 'Gross (before tax)',
  },

  // ── SAS FO A320 Sweden — net submissions ──
  {
    deviceId: 'test_sas_fo_se_01',
    airlineId: 'sas',
    airline: 'SAS',
    rank: 'FO',
    seniorityYears: 5,
    aircraftType: 'A320',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 45000,
    allInMonthlyEstimate: 55000,
    country: 'Sweden',
    base: 'Stockholm',
    currency: 'SEK',
    amountType: 'Net (after tax)',
  },
  {
    deviceId: 'test_sas_fo_se_02',
    airlineId: 'sas',
    airline: 'SAS',
    rank: 'FO',
    seniorityYears: 8,
    aircraftType: 'A320',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 50000,
    country: 'Sweden',
    base: 'Stockholm',
    currency: 'SEK',
    amountType: 'Net (after tax)',
  },
  {
    deviceId: 'test_sas_fo_se_03',
    airlineId: 'sas',
    airline: 'SAS',
    rank: 'FO',
    seniorityYears: 6,
    aircraftType: 'A320',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 47000,
    allInMonthlyEstimate: 58000,
    country: 'Sweden',
    base: 'Gothenburg',
    currency: 'SEK',
    amountType: 'Net (after tax)',
  },

  // ── Lufthansa FO A320 Germany (gross, seniority only) ──
  {
    deviceId: 'test_lh_fo_de_01',
    airlineId: 'lufthansa',
    airline: 'Lufthansa',
    rank: 'FO',
    seniorityYears: 4,
    aircraftType: 'A320',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 6500,
    country: 'Germany',
    base: 'Frankfurt',
    currency: 'EUR',
    amountType: 'Gross (before tax)',
  },
  {
    deviceId: 'test_lh_fo_de_02',
    airlineId: 'lufthansa',
    airline: 'Lufthansa',
    rank: 'FO',
    seniorityYears: 6,
    aircraftType: 'A320',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 7000,
    allInMonthlyEstimate: 8800,
    country: 'Germany',
    base: 'Munich',
    currency: 'EUR',
    amountType: 'Gross (before tax)',
  },
  {
    deviceId: 'test_lh_fo_de_03',
    airlineId: 'lufthansa',
    airline: 'Lufthansa',
    rank: 'FO',
    seniorityYears: 8,
    aircraftType: 'A320',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 7500,
    country: 'Germany',
    base: 'Frankfurt',
    currency: 'EUR',
    amountType: 'Gross (before tax)',
  },

  // ── Finnair mixed (gross, both seniority and hours) ──
  {
    deviceId: 'test_finnair_fo_fi_01',
    airlineId: 'finnair',
    airline: 'Finnair',
    rank: 'FO',
    seniorityYears: 3,
    totalFlightHours: 3000,
    aircraftType: 'A320',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 5800,
    country: 'Finland',
    base: 'Helsinki',
    currency: 'EUR',
    amountType: 'Gross (before tax)',
  },
  {
    deviceId: 'test_finnair_fo_fi_02',
    airlineId: 'finnair',
    airline: 'Finnair',
    rank: 'FO',
    seniorityYears: 10,
    aircraftType: 'A350',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 8500,
    allInMonthlyEstimate: 10800,
    country: 'Finland',
    base: 'Helsinki',
    currency: 'EUR',
    amountType: 'Gross (before tax)',
  },
  {
    deviceId: 'test_finnair_cap_fi_01',
    airlineId: 'finnair',
    airline: 'Finnair',
    rank: 'Captain',
    seniorityYears: 20,
    aircraftType: 'A350',
    contractType: 'Permanent',
    guaranteedMonthlyPay: 13000,
    allInMonthlyEstimate: 16000,
    country: 'Finland',
    base: 'Helsinki',
    currency: 'EUR',
    amountType: 'Gross (before tax)',
  },

  // ── Wizz Air FO A320 Hungary (gross, flight hours only) ──
  {
    deviceId: 'test_wizz_fo_hu_01',
    airlineId: 'wizz_air',
    airline: 'Wizz Air',
    rank: 'FO',
    seniorityYears: 0,
    totalFlightHours: 2500,
    aircraftType: 'A320',
    contractType: 'Contractor',
    guaranteedMonthlyPay: 4500,
    country: 'Hungary',
    base: 'Budapest',
    currency: 'EUR',
    amountType: 'Gross (before tax)',
  },
  {
    deviceId: 'test_wizz_fo_hu_02',
    airlineId: 'wizz_air',
    airline: 'Wizz Air',
    rank: 'FO',
    seniorityYears: 5,
    aircraftType: 'A320',
    contractType: 'Contractor',
    guaranteedMonthlyPay: 4800,
    allInMonthlyEstimate: 6200,
    country: 'Hungary',
    base: 'Budapest',
    currency: 'EUR',
    amountType: 'Gross (before tax)',
  },
  {
    deviceId: 'test_wizz_fo_hu_03',
    airlineId: 'wizz_air',
    airline: 'Wizz Air',
    rank: 'FO',
    seniorityYears: 0,
    totalFlightHours: 3800,
    aircraftType: 'A320',
    contractType: 'Contractor',
    guaranteedMonthlyPay: 5100,
    country: 'Hungary',
    base: 'Budapest',
    currency: 'EUR',
    amountType: 'Gross (before tax)',
  },

  // ── Ryanair Captain 737-800 Ireland (gross) ──
  {
    deviceId: 'test_ryanair_cap_ie_01',
    airlineId: 'ryanair',
    airline: 'Ryanair',
    rank: 'Captain',
    seniorityYears: 12,
    totalFlightHours: 11000,
    aircraftType: '737-800',
    contractType: 'Contractor',
    guaranteedMonthlyPay: 9500,
    allInMonthlyEstimate: 12500,
    country: 'Ireland',
    base: 'Dublin',
    currency: 'EUR',
    amountType: 'Gross (before tax)',
  },
  {
    deviceId: 'test_ryanair_cap_ie_02',
    airlineId: 'ryanair',
    airline: 'Ryanair',
    rank: 'Captain',
    seniorityYears: 15,
    aircraftType: '737-800',
    contractType: 'Contractor',
    guaranteedMonthlyPay: 10000,
    country: 'Ireland',
    base: 'Dublin',
    currency: 'EUR',
    amountType: 'Gross (before tax)',
  },
];

function toFirestoreValue(val) {
  if (val === null || val === undefined) return { nullValue: null };
  if (typeof val === 'string') return { stringValue: val };
  if (typeof val === 'boolean') return { booleanValue: val };
  if (Number.isInteger(val)) return { integerValue: String(val) };
  if (typeof val === 'number') return { doubleValue: val };
  throw new Error(`Unsupported type: ${typeof val}`);
}

function toFirestoreFields(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj)) {
    if (v !== undefined && v !== null) {
      fields[k] = toFirestoreValue(v);
    }
  }
  fields['createdAt'] = { timestampValue: new Date().toISOString() };
  return fields;
}

async function addDocument(data) {
  const body = JSON.stringify({ fields: toFirestoreFields(data) });
  const url = `${BASE_URL}?key=${API_KEY}`;
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body,
  });
  if (!res.ok) {
    const err = await res.text();
    throw new Error(`HTTP ${res.status}: ${err}`);
  }
  return res.json();
}

async function main() {
  console.log(`Seeding ${submissions.length} salary submissions...`);
  let ok = 0;
  let fail = 0;
  for (const s of submissions) {
    try {
      const result = await addDocument(s);
      const id = result.name.split('/').pop();
      console.log(`✓ ${s.deviceId} → ${id}`);
      ok++;
    } catch (e) {
      console.error(`✗ ${s.deviceId}: ${e.message}`);
      fail++;
    }
  }
  console.log(`\nDone: ${ok} added, ${fail} failed.`);
}

main();
