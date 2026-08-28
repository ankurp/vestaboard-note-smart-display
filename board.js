import {
  assertConfig,
  isWeatherConfigured,
  UPDATE_INTERVAL_MS,
  WEATHER_HOUR_END,
  WEATHER_HOUR_START,
} from "./src/config.js";
import { boardsEqual, sendBoard } from "./src/display.js";
import { buildClockBoard } from "./src/clock.js";
import { getWeatherBoard } from "./src/weather.js";
import { buildEventBoard, getImminentEvents } from "./src/calendar.js";

/**
 * Main process. Every minute it selects a board by priority and pushes it to
 * the Vestaboard only when the layout has changed:
 *   1. Event   - an event starts within the next hour
 *   2. Weather - the morning weather window
 *   3. Default - the idle kitchen/date display
 */

function isWeatherWindow(now = new Date()) {
  const hour = now.getHours();
  return hour >= WEATHER_HOUR_START && hour < WEATHER_HOUR_END;
}

async function pickBoard() {
  // 1. An imminent event takes over the board.
  try {
    const imminent = getImminentEvents();
    if (imminent.length > 0) {
      return { mode: "event", board: buildEventBoard(imminent) };
    }
  } catch (err) {
    console.error("Event lookup failed:", err.message);
  }

  // 2. Morning weather window.
  if (isWeatherConfigured() && isWeatherWindow()) {
    const board = await getWeatherBoard();
    if (board) return { mode: "weather", board };
  }

  // 3. Default idle display.
  return { mode: "default", board: buildClockBoard() };
}

let lastBoard = null;

async function update() {
  const timeStr = new Date().toLocaleTimeString();
  const { mode, board } = await pickBoard();

  if (lastBoard && boardsEqual(board, lastBoard)) {
    console.log(`[${timeStr}] ${mode}: unchanged, skipping.`);
    return;
  }

  console.log(`[${timeStr}] ${mode}: updating board...`);
  const result = await sendBoard(board);
  lastBoard = board;
  console.log(`[${timeStr}] Done:`, result.status || "ok");
}

async function tick() {
  try {
    await update();
  } catch (err) {
    console.error("Update failed:", err.message);
  }
}

assertConfig();
await tick();
setInterval(tick, UPDATE_INTERVAL_MS);
console.log("Board running. Checking every minute. Press Ctrl+C to stop.");
