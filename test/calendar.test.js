import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { formatTime, parseEventDate, selectImminent } from "../src/calendar.js";

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
