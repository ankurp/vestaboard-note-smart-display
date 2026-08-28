import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { buildClockBoard } from "../src/clock.js";
import { CHARS } from "../src/display.js";

describe("clock", () => {
  it("builds a 3x15 board", () => {
    const board = buildClockBoard(new Date("2026-08-28T09:00:00"));
    assert.equal(board.length, 3);
    assert.ok(board.every((row) => row.length === 15));
  });

  it("includes the heart character on the second row", () => {
    const board = buildClockBoard(new Date("2026-08-28T09:00:00"));
    assert.ok(board[1].includes(CHARS.HEART));
  });

  it("renders the weekday and date", () => {
    // 2026-08-28 is a Friday.
    const board = buildClockBoard(new Date("2026-08-28T09:00:00"));
    const codes = board[2].filter((c) => c !== 0);
    // "FRI 08/28/2026" -> starts with F, R, I.
    assert.deepEqual(codes.slice(0, 3), [6, 18, 9]);
  });
});
