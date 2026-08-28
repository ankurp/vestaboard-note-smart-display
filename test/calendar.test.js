import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { buildEventBoard, formatTime, parseEventDate, selectImminent } from "../src/calendar.js";
import { CHARS } from "../src/display.js";

describe("formatTime", () => {
  it("returns ALL for all-day events", () => {
    assert.equal(formatTime("anything", true), "ALL");
  });

  it("parses 12-hour times into 24-hour HH:MM", () => {
    assert.equal(formatTime("Fri, Aug 28, 2026 at 6:30:00 PM", false), "18:30");
    assert.equal(formatTime("Fri, Aug 28, 2026 at 12:05:00 AM", false), "00:05");
    assert.equal(formatTime("Fri, Aug 28, 2026 at 12:00:00 PM", false), "12:00");
  });

  it("parses 24-hour times", () => {
    assert.equal(formatTime("2026-08-28 16:30:00", false), "16:30");
  });

  it("returns empty string when no time is present", () => {
    assert.equal(formatTime("no time here", false), "");
  });
});

describe("parseEventDate", () => {
  it("parses the helper date format", () => {
    const date = parseEventDate("Fri, Aug 28, 2026 at 6:30:00 PM");
    assert.ok(date instanceof Date);
    assert.equal(date.getHours(), 18);
    assert.equal(date.getMinutes(), 30);
  });

  it("returns null for unparseable input", () => {
    assert.equal(parseEventDate("not a date"), null);
  });
});

describe("selectImminent", () => {
  const now = new Date("2026-08-28T12:00:00");
  const at = (mins) => new Date(now.getTime() + mins * 60_000);

  it("keeps events starting within the next 60 minutes", () => {
    const events = [
      { summary: "Soon", start: "", date: at(30), allDay: false },
      { summary: "TooFar", start: "", date: at(90), allDay: false },
      { summary: "Past", start: "", date: at(-10), allDay: false },
    ];
    const result = selectImminent(events, now);
    assert.deepEqual(
      result.map((e) => e.summary),
      ["Soon"],
    );
  });

  it("sorts by soonest first", () => {
    const events = [
      { summary: "Later", start: "", date: at(45), allDay: false },
      { summary: "Sooner", start: "", date: at(5), allDay: false },
    ];
    const result = selectImminent(events, now);
    assert.deepEqual(
      result.map((e) => e.summary),
      ["Sooner", "Later"],
    );
  });

  it("excludes all-day events", () => {
    const events = [{ summary: "AllDay", start: "", date: at(10), allDay: true }];
    assert.equal(selectImminent(events, now).length, 0);
  });

  it("limits the result to three events", () => {
    const events = Array.from({ length: 5 }, (_, i) => ({
      summary: `E${i}`,
      start: "",
      date: at(i + 1),
      allDay: false,
    }));
    assert.equal(selectImminent(events, now).length, 3);
  });
});

describe("buildEventBoard (single event)", () => {
  const soon = new Date(Date.now() + 30 * 60_000);
  const event = { summary: "Soccer Practice", start: "", date: soon, allDay: false };

  it("produces a 3x15 board", () => {
    const board = buildEventBoard([event]);
    assert.equal(board.length, 3);
    assert.ok(board.every((row) => row.length === 15));
  });

  it("renders the event name on the first row", () => {
    const board = buildEventBoard([event]);
    const codes = board[0].filter((c) => c !== 0);
    // "SOCCER PRACTICE" -> starts with S, O, C
    assert.deepEqual(codes.slice(0, 3), [19, 15, 3]);
  });

  it("frames the time row with color chips (RED for today)", () => {
    const board = buildEventBoard([event]);
    const chips = board[1].filter((c) => c === CHARS.RED);
    assert.equal(chips.length, 2);
  });
});
