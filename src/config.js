import "dotenv/config";

/**
 * Centralized configuration and behavior tuning, sourced from environment
 * variables with sensible defaults.
 */

export const VESTABOARD_TOKEN = process.env.VESTABOARD_TOKEN;
export const ZIP_CODE = process.env.ZIP_CODE;
export const CITY = process.env.CITY;

export const CALENDAR_NAMES = (process.env.CALENDAR_NAME || "Family")
  .split(",")
  .map((name) => name.trim())
  .filter(Boolean);

// Vestaboard Note geometry.
export const ROWS = 3;
export const COLS = 15;

// Behavior tuning.
export const EVENT_WINDOW_MINUTES = 60; // How soon an event takes over the board.
export const WEATHER_HOUR_START = 7; // Weather window begins (24h, inclusive).
export const WEATHER_HOUR_END = 8; // Weather window ends (24h, exclusive).
export const WEATHER_CACHE_MS = 30 * 60_000; // How long weather stays fresh.
export const UPDATE_INTERVAL_MS = 60_000; // How often the board is re-evaluated.

/** Throws if required configuration is missing. */
export function assertConfig() {
  if (!VESTABOARD_TOKEN) {
    throw new Error("VESTABOARD_TOKEN is required in .env");
  }
}

/** Whether a weather location has been configured. */
export function isWeatherConfigured() {
  return Boolean(ZIP_CODE || CITY);
}
