#!/usr/bin/env node
/** Generate app_en.arb and app_fr.arb from tool/generate_l10n_arb.py string data. */
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, "..", "lib", "l10n");
const PY_PATH = join(__dirname, "generate_l10n_arb.py");

function skipWs(s, i) {
  while (i < s.length && /[\s,]/.test(s[i])) i++;
  return i;
}

function readQuotedString(s, i) {
  const quote = s[i];
  if (quote !== '"' && quote !== "'") {
    throw new Error(`Expected string at ${i}`);
  }
  i++;
  let out = "";
  while (i < s.length) {
    const ch = s[i];
    if (ch === "\\") {
      const next = s[i + 1];
      if (next === undefined) throw new Error("Bad escape");
      out += next;
      i += 2;
      continue;
    }
    if (ch === quote) return { value: out, next: i + 1 };
    out += ch;
    i++;
  }
  throw new Error("Unterminated string");
}

function findDictBody(source, varName) {
  const marker = `${varName} = {`;
  const start = source.indexOf(marker);
  if (start < 0) throw new Error(`Missing ${varName} in ${PY_PATH}`);
  let i = start + marker.length;
  let depth = 1;
  const bodyStart = i;
  while (i < source.length && depth > 0) {
    const ch = source[i];
    if (ch === '"' || ch === "'") {
      i = readQuotedString(source, i).next;
      continue;
    }
    if (ch === "{") depth++;
    else if (ch === "}") depth--;
    if (depth > 0) i++;
  }
  return source.slice(bodyStart, i - 1);
}

function parseStringDict(body) {
  const result = {};
  let i = 0;
  while (i < body.length) {
    i = skipWs(body, i);
    if (i >= body.length) break;
    if (body[i] === "#") {
      const nl = body.indexOf("\n", i);
      i = nl < 0 ? body.length : nl + 1;
      continue;
    }
    if (body[i] !== '"') {
      const nl = body.indexOf("\n", i);
      i = nl < 0 ? body.length : nl + 1;
      continue;
    }
    const keyPart = readQuotedString(body, i);
    const key = keyPart.value;
    i = skipWs(body, keyPart.next);
    if (body[i] !== ":") throw new Error(`Expected : after key ${key}`);
    i++;
    i = skipWs(body, i);
    const valPart = readQuotedString(body, i);
    result[key] = valPart.value;
    i = valPart.next;
  }
  return result;
}

function parsePlaceholderTypes(source) {
  const body = findDictBody(source, "PLACEHOLDER_TYPES");
  const types = {};
  const re = /"(\w+)":\s*(?:"(String|int)"|(String|int))/g;
  let m;
  while ((m = re.exec(body)) !== null) {
    types[m[1]] = m[2] ?? m[3];
  }
  return types;
}

function loadFromPythonSource() {
  const source = readFileSync(PY_PATH, "utf8");
  const en = parseStringDict(findDictBody(source, "EN_STRINGS"));
  const fr = parseStringDict(findDictBody(source, "FR_STRINGS"));
  const placeholderTypes = parsePlaceholderTypes(source);
  return { en, fr, placeholderTypes };
}

function extractPlaceholders(value, placeholderTypes) {
  const placeholders = {};
  const re = /\{(\w+)/g;
  let match;
  while ((match = re.exec(value)) !== null) {
    const name = match[1];
    if (/^\d+$/.test(name)) continue;
    if (name === "count" && value.includes("plural")) {
      placeholders[name] = { type: "int" };
    } else if (name === "plural") continue;
    else if (placeholderTypes[name]) {
      placeholders[name] = { type: placeholderTypes[name] };
    } else {
      placeholders[name] = { type: "String" };
    }
  }
  return placeholders;
}

function buildArb(strings, locale, placeholderTypes) {
  const arb = {};
  if (locale) arb["@@locale"] = locale;
  for (const [key, value] of Object.entries(strings)) {
    arb[key] = value;
    if (value.includes("{") && !key.startsWith("@")) {
      const ph = extractPlaceholders(value, placeholderTypes);
      if (Object.keys(ph).length > 0) {
        arb[`@${key}`] = { placeholders: ph };
      }
    }
  }
  return arb;
}

function main() {
  const { en: EN_STRINGS, fr: FR_STRINGS, placeholderTypes } = loadFromPythonSource();
  mkdirSync(ROOT, { recursive: true });

  const enArb = buildArb(EN_STRINGS, "en", placeholderTypes);
  let frArb = buildArb(FR_STRINGS, "fr", placeholderTypes);

  for (const key of Object.keys(enArb)) {
    if (key.startsWith("@") && !(key in frArb)) {
      frArb[key] = enArb[key];
    }
  }

  const missingFr = Object.keys(EN_STRINGS).filter((k) => !(k in FR_STRINGS));
  if (missingFr.length > 0) {
    console.warn("WARNING: missing FR keys:", missingFr);
  }

  const jsonOpts = (obj) => JSON.stringify(obj, null, 2) + "\n";
  writeFileSync(join(ROOT, "app_en.arb"), jsonOpts(enArb), "utf8");
  writeFileSync(join(ROOT, "app_fr.arb"), jsonOpts(frArb), "utf8");
  console.log(`Generated ${Object.keys(EN_STRINGS).length} keys -> ${ROOT}`);
}

main();