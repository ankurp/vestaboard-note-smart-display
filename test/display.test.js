import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  blankRow,
  boardsEqual,
  centerRow,
  CHARS,
  leftRow,
  textToCharCodes,
} from "../src/display.js";

describe("display", () => {
  it("maps text to character codes, uppercasing input", () => {
    assert.deepEqual(textToCharCodes("AB"), [1, 2]);
    assert.deepEqual(textToCharCodes("ab"), [1, 2]);
  });

  it("maps unknown characters to blank", () => {
    assert.deepEqual(textToCharCodes("~"), [CHARS.BLANK]);
  });

  it("builds a full-width blank row", () => {
    const row = blankRow();
    assert.equal(row.length, 15);
    assert.ok(row.every((cell) => cell === 0));
  });

  it("centers codes within a 15-wide row", () => {
    const row = centerRow(textToCharCodes("HI"));
    assert.equal(row.length, 15);
    // "HI" (2 chars) -> padding of 6 on the left.
    assert.deepEqual(row.slice(6, 8), [8, 9]);
  });

  it("left-aligns codes within a 15-wide row", () => {
    const row = leftRow(textToCharCodes("HI"));
    assert.equal(row.length, 15);
    assert.deepEqual(row.slice(0, 2), [8, 9]);
  });

  it("truncates rows longer than the board width", () => {
    const row = centerRow(textToCharCodes("ABCDEFGHIJKLMNOPQRST"));
    assert.equal(row.length, 15);
  });

  it("compares boards for deep equality", () => {
    const a = [blankRow(), blankRow(), blankRow()];
    const b = [blankRow(), blankRow(), blankRow()];
    assert.ok(boardsEqual(a, b));
    b[0][0] = 1;
    assert.ok(!boardsEqual(a, b));
  });
});
