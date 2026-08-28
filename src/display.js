import { COLS, VESTABOARD_TOKEN } from "./config.js";

/**
 * Vestaboard character encoding, row-building helpers, and the Cloud API
 * client. A "board" is an array of rows; each row is an array of character
 * codes.
 */

const VESTABOARD_URL = "https://cloud.vestaboard.com/";

// Named character codes for the Vestaboard Note.
export const CHARS = {
  BLANK: 0,
  HEART: 62,
  DEGREE: 62,
  RED: 63, // Color chip used for today's events.
  GREEN: 66, // Color chip used for future events.
};

const CHAR_MAP = {
  " ": 0,
  A: 1,
  B: 2,
  C: 3,
  D: 4,
  E: 5,
  F: 6,
  G: 7,
  H: 8,
  I: 9,
  J: 10,
  K: 11,
  L: 12,
  M: 13,
  N: 14,
  O: 15,
  P: 16,
  Q: 17,
  R: 18,
  S: 19,
  T: 20,
  U: 21,
  V: 22,
  W: 23,
  X: 24,
  Y: 25,
  Z: 26,
  1: 27,
  2: 28,
  3: 29,
  4: 30,
  5: 31,
  6: 32,
  7: 33,
  8: 34,
  9: 35,
  0: 36,
  "!": 37,
  "@": 38,
  "#": 39,
  $: 40,
  "(": 41,
  ")": 42,
  "-": 44,
  "+": 46,
  "&": 47,
  "=": 48,
  ";": 49,
  ":": 50,
  "'": 52,
  '"': 53,
  "%": 54,
  ",": 55,
  ".": 56,
  "/": 59,
  "?": 60,
  "°": 62,
};

/** Converts text into an array of Vestaboard character codes. */
export function textToCharCodes(text) {
  return [...text.toUpperCase()].map((ch) => CHAR_MAP[ch] ?? CHARS.BLANK);
}

/** Returns a full-width blank row. */
export function blankRow() {
  return new Array(COLS).fill(CHARS.BLANK);
}

/** Places codes into a centered, full-width row (truncating if too long). */
export function centerRow(codes) {
  if (codes.length >= COLS) return codes.slice(0, COLS);
  const padding = Math.floor((COLS - codes.length) / 2);
  const row = blankRow();
  for (let i = 0; i < codes.length; i++) {
    row[padding + i] = codes[i];
  }
  return row;
}

/** Places codes into a left-aligned, full-width row (truncating if too long). */
export function leftRow(codes) {
  if (codes.length >= COLS) return codes.slice(0, COLS);
  const row = blankRow();
  for (let i = 0; i < codes.length; i++) {
    row[i] = codes[i];
  }
  return row;
}

/** Deep-compares two boards for equality. */
export function boardsEqual(a, b) {
  return JSON.stringify(a) === JSON.stringify(b);
}

/**
 * Sends a board to the Vestaboard. A 409 (fingerprint match) means the board
 * already shows this message and is treated as success.
 */
export async function sendBoard(board) {
  const res = await fetch(VESTABOARD_URL, {
    method: "POST",
    headers: {
      "X-Vestaboard-Token": VESTABOARD_TOKEN,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ characters: board }),
  });

  if (!res.ok) {
    if (res.status === 409) return { status: "unchanged" };
    throw new Error(`Vestaboard API error: ${res.status} - ${await res.text()}`);
  }

  return res.json();
}
