import { execSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { CALENDAR_NAMES, COLS, EVENT_WINDOW_MINUTES } from "./config.js";
import { blankRow, centerRow, CHARS, textToCharCodes } from "./display.js";

/**
 * Reads upcoming events from the macOS Calendar (via the `get-events` helper)
 * and renders imminent ones as a board, shortening names with the `summarize`
 * helper.
 */

// Directory holding the compiled Swift helpers.
const NATIVE_DIR = fileURLToPath(new URL("../native/", import.meta.url));
const MAX_EVENTS = 3;
const MAX_SUMMARY_LEN = 9;

// Maps original event name -> shortened display name.
const summaryCache = new Map();

function runHelper(command) {
  return execSync(command, {
    timeout: 30_000,
    encoding: "utf-8",
    cwd: NATIVE_DIR,
  }).trim();
}

/** Parses the helper's date string ("Thu, May 22, 2026 at 6:30:00 PM"). */
export function parseEventDate(dateStr) {
  const date = new Date(dateStr.replace(" at ", " "));
  return Number.isNaN(date.getTime()) ? null : date;
}

/** Formats an event start time as "HH:MM" (or "ALL" for all-day events). */
export function formatTime(dateStr, allDay) {
  if (allDay) return "ALL";

  const match12 = dateStr.match(/(\d{1,2}):(\d{2}):\d{2}\s*(AM|PM)/i);
  if (match12) {
    let hour = parseInt(match12[1], 10);
    const period = match12[3].toUpperCase();
    if (period === "PM" && hour !== 12) hour += 12;
    if (period === "AM" && hour === 12) hour = 0;
    return `${String(hour).padStart(2, "0")}:${match12[2]}`;
  }

  const match24 = dateStr.match(/(\d{1,2}):(\d{2}):\d{2}/);
  if (match24) {
    return `${String(parseInt(match24[1], 10)).padStart(2, "0")}:${match24[2]}`;
  }

  return "";
}

function isToday(date) {
  const now = new Date();
  return (
    date.getFullYear() === now.getFullYear() &&
    date.getMonth() === now.getMonth() &&
    date.getDate() === now.getDate()
  );
}

/** Fetches upcoming timed events across the configured calendars (skips all-day). */
function getUpcomingEvents() {
  const output = runHelper(`./get-events "${CALENDAR_NAMES.join(",")}"`);
  if (!output) return [];

  return output
    .split("\n")
    .filter(Boolean)
    .map((line) => {
      const [summary, start, allDay] = line.split("||");
      return {
        summary: summary.trim(),
        start: start.trim(),
        allDay: allDay.trim() === "true",
      };
    })
    .filter((event) => !event.allDay);
}

/** Shortens event names to fit the display, caching results per name. */
function summarizeEvents(events) {
  const names = events.map((event) => event.summary || "EVENT");
  const truncate = (name) => name.toUpperCase().slice(0, MAX_SUMMARY_LEN);
  const uncached = names.filter((name) => !summaryCache.has(name));

  if (uncached.length > 0) {
    try {
      const args = uncached.map((name) => `"${name.replace(/"/g, '\\"')}"`).join(" ");
      const lines = runHelper(`./summarize ${args}`)
        .split("\n")
        .map((line) => line.trim().toUpperCase().slice(0, MAX_SUMMARY_LEN));
      uncached.forEach((name, i) => summaryCache.set(name, lines[i] || truncate(name)));
    } catch (err) {
      console.error("Summarize failed, falling back to truncation:", err.message);
      uncached.forEach((name) => summaryCache.set(name, truncate(name)));
    }
  }

  return names.map((name) => summaryCache.get(name));
}

/** Filters events to those starting within the window, soonest first (pure). */
export function selectImminent(events, now = new Date()) {
  const cutoff = new Date(now.getTime() + EVENT_WINDOW_MINUTES * 60_000);

  return events
    .map((event) => ({ ...event, date: event.date ?? parseEventDate(event.start) }))
    .filter((event) => !event.allDay && event.date && event.date > now && event.date <= cutoff)
    .sort((a, b) => a.date - b.date)
    .slice(0, MAX_EVENTS);
}

/** Returns events starting within the next EVENT_WINDOW_MINUTES, soonest first. */
export function getImminentEvents(now = new Date()) {
  return selectImminent(getUpcomingEvents(), now);
}

/** Renders events as a board. A single event uses the whole board; multiple
 * events use one compact "HH:MM<color>SUMMARY" row each. */
export function buildEventBoard(events) {
  if (events.length === 1) return buildSingleEventBoard(events[0]);

  const summaries = summarizeEvents(events);

  return Array.from({ length: 3 }, (_, i) => {
    if (i >= events.length) return blankRow();

    const event = events[i];
    const colorCode = event.date && isToday(event.date) ? CHARS.RED : CHARS.GREEN;
    const codes = [
      ...textToCharCodes(formatTime(event.start, event.allDay)),
      colorCode,
      ...textToCharCodes(summaries[i]),
    ];

    const row = blankRow();
    for (let j = 0; j < Math.min(codes.length, COLS); j++) {
      row[j] = codes[j];
    }
    return row;
  });
}

/** Formats a time as "6:30 PM" for the roomier single-event layout. */
function formatTime12(event) {
  const date = event.date ?? parseEventDate(event.start);
  if (!date) return formatTime(event.start, event.allDay);

  let hour = date.getHours();
  const minute = String(date.getMinutes()).padStart(2, "0");
  const period = hour >= 12 ? "PM" : "AM";
  hour %= 12;
  if (hour === 0) hour = 12;
  return `${hour}:${minute} ${period}`;
}

/** Relative day label: "TODAY" or the full weekday name. */
function dayLabel(date) {
  const weekdays = ["SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY"];
  if (!date) return "";
  return isToday(date) ? "TODAY" : weekdays[date.getDay()];
}

/** Full-board layout for a single event: name, framed time, and day. */
function buildSingleEventBoard(event) {
  const date = event.date ?? parseEventDate(event.start);
  const color = date && isToday(date) ? CHARS.RED : CHARS.GREEN;
  const name = (event.summary || "EVENT").toUpperCase().slice(0, COLS);
  const timeCodes = textToCharCodes(formatTime12(event));

  return [
    centerRow(textToCharCodes(name)),
    centerRow([color, CHARS.BLANK, ...timeCodes, CHARS.BLANK, color]),
    centerRow(textToCharCodes(dayLabel(date))),
  ];
}
