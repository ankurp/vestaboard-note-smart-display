import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { buildWeatherBoard } from "../src/weather.js";

describe("buildWeatherBoard", () => {
  const weather = { current: { temperature_2m: 71.6, weather_code: 0 } };

  it("builds a 3x15 board", () => {
    const board = buildWeatherBoard(weather, "Irvine");
    assert.equal(board.length, 3);
    assert.ok(board.every((row) => row.length === 15));
  });

  it("rounds the temperature", () => {
    const board = buildWeatherBoard(weather, "Irvine");
    // 71.6 -> 72; "72°F" -> 7, 2, degree, F
    const codes = board[1].filter((c) => c !== 0);
    assert.deepEqual(codes, [33, 28, 62, 6]);
  });

  it("falls back to WEATHER for unknown codes", () => {
    const board = buildWeatherBoard({ current: { temperature_2m: 50, weather_code: 999 } }, "X");
    const codes = board[2].filter((c) => c !== 0);
    // "WEATHER" -> W E A T H E R
    assert.deepEqual(codes, [23, 5, 1, 20, 8, 5, 18]);
  });
});
