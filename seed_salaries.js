#!/usr/bin/env node
// Seed 50 realistic pilot salary documents into Firestore "salaries" collection.
// Uses ADC access token — run after: gcloud auth application-default login

const https = require('https');
const crypto = require('crypto');

const PROJECT_ID = 'passrate-4360d';
const API_KEY    = 'AIzaSyAACELQ70qc3CbCAQm3XMASRZDR5f54j7A';
const FIRESTORE_URL = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/salaries?key=${API_KEY}`;

// ── Location data ────────────────────────────────────────────────────────────
const locations = {
  Norway:  { city: 'Oslo',       currency: 'NOK' },
  UK:      { city: 'London',     currency: 'GBP' },
  Germany: { city: 'Berlin',     currency: 'EUR' },
  Sweden:  { city: 'Stockholm',  currency: 'SEK' },
  Denmark: { city: 'Copenhagen', currency: 'DKK' },
  Finland: { city: 'Helsinki',   currency: 'EUR' },
  Ireland: { city: 'Dublin',     currency: 'EUR' },
  UAE:     { city: 'Dubai',      currency: 'AED' },
  Qatar:   { city: 'Doha',       currency: 'QAR' },
};

// ── Airline → typical operating countries ────────────────────────────────────
const airlineCountries = {
  'SAS':             ['Norway', 'Sweden', 'Denmark'],
  'Norwegian':       ['Norway', 'UK'],
  'Ryanair':         ['Ireland', 'UK', 'Germany'],
  'Wizz Air':        ['UK', 'Germany'],
  'British Airways': ['UK'],
  'Lufthansa':       ['Germany'],
  'KLM':             ['Germany', 'UK'],
  'Finnair':         ['Finland', 'Germany'],
  'TUI':             ['UK', 'Germany'],
  'EasyJet':         ['UK', 'Germany'],
  'Emirates':        ['UAE'],
  'Qatar Airways':   ['Qatar'],
};

const airlines = Object.keys(airlineCountries);

// ── Rank weights: 20% SO, 50% FO, 30% Captain ────────────────────────────────
function pickRank() {
  const r = Math.random();
  if (r < 0.20) return 'SO';
  if (r < 0.70) return 'FO';
  return 'Captain';
}

// ── Seniority ────────────────────────────────────────────────────────────────
function pickSeniority(rank) {
  if (rank === 'SO') return randInt(1, 3);
  if (rank === 'FO') return randInt(2, 12);
  return randInt(5, 20);
}

// ── Salary ranges (monthly, local currency) ──────────────────────────────────
function pickSalary(rank) {
  if (rank === 'SO')      return randInt(3000,  5000);
  if (rank === 'FO')      return randInt(5000,  9000);
  return                         randInt(9000, 18000);
}

// ── Aircraft type – widebody bias for Emirates/Qatar ─────────────────────────
function pickAircraft(airline) {
  const widebodyBias = ['Emirates', 'Qatar Airways', 'British Airways', 'Lufthansa', 'KLM', 'Finnair', 'SAS'];
  const p = widebodyBias.includes(airline) ? 0.65 : 0.25;
  return Math.random() < p ? 'Widebody' : 'Narrowbody';
}

// ── Helpers ──────────────────────────────────────────────────────────────────
function randInt(min, max) { return Math.floor(Math.random() * (max - min + 1)) + min; }
function pick(arr)          { return arr[Math.floor(Math.random() * arr.length)]; }
function uid()              { return crypto.randomUUID(); }

// ── Build a Firestore REST document body ─────────────────────────────────────
function toFirestoreDoc(data) {
  const fields = {};
  for (const [k, v] of Object.entries(data)) {
    if (typeof v === 'string')  fields[k] = { stringValue: v };
    else if (Number.isInteger(v)) fields[k] = { integerValue: String(v) };
    else if (typeof v === 'number') fields[k] = { doubleValue: v };
  }
  return JSON.stringify({ fields });
}

// ── POST one document ─────────────────────────────────────────────────────────
function postDoc(body) {
  return new Promise((resolve, reject) => {
    const req = https.request(FIRESTORE_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
      },
    }, (res) => {
      let data = '';
      res.on('data', d => data += d);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// ── Generate 50 documents and write them ─────────────────────────────────────
async function main() {
  console.log(`Seeding 50 salary documents to project "${PROJECT_ID}"…\n`);

  for (let i = 1; i <= 50; i++) {
    const airline  = pick(airlines);
    const rank     = pickRank();
    const country  = pick(airlineCountries[airline]);
    const loc      = locations[country];
    const salary   = pickSalary(rank);
    const perDiem  = randInt(30, 80);

    const doc = {
      deviceId:     `seed-${uid()}`,
      airlineId:    airline.toLowerCase().replace(/\s+/g, '-'),
      airline,
      rank,
      seniorityYears: pickSeniority(rank),
      aircraftType:   pickAircraft(airline),
      contractType:   Math.random() < 0.75 ? 'Permanent' : 'Contractor',
      baseSalary:     salary,
      perDiem,
      country,
      base:           loc.city,
      currency:       loc.currency,
    };

    try {
      await postDoc(toFirestoreDoc(doc));
      console.log(`[${i}/50] ✓  ${airline.padEnd(16)} ${rank.padEnd(8)} ${country.padEnd(10)} ${loc.currency} ${salary}`);
    } catch (err) {
      console.error(`[${i}/50] ✗  ${airline} — ${err.message}`);
    }
  }

  console.log('\nDone.');
}

main().catch(console.error);
