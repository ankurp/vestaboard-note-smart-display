import { CITY, COLS, WEATHER_CACHE_MS, ZIP_CODE } from "./config.js";
import { centerRow, textToCharCodes } from "./display.js";

/** Fetches local weather from Open-Meteo and renders it as a board. */

const GEOCODE_URL = "https://geocoding-api.open-meteo.com/v1/search";
const ZIP_URL = "https://api.zippopotam.us/us";
const FORECAST_URL = "https://api.open-meteo.com/v1/forecast";

const WEATHER_DESCRIPTIONS = {
  0: "CLEAR",
  1: "MOSTLY CLR",
  2: "PARTLY CLD",
  3: "OVERCAST",
  45: "FOG",
  48: "RIME FOG",
  51: "LIGHT DRZL",
  53: "MOD DRIZZL",
  55: "DENSE DRZL",
  61: "LIGHT RAIN",
  63: "RAIN",
  65: "HEAVY RAIN",
  71: "LIGHT SNOW",
  73: "SNOW",
  75: "HEAVY SNOW",
  77: "SNOW GRAIN",
  80: "LGT SHOWER",
  81: "SHOWERS",
  82: "HVY SHOWER",
  85: "SNOW SHWR",
  86: "HVY SN SHR",
  95: "TSTORM",
  96: "TSTORM+HAL",
  99: "HVY TSTRM",
};

let cachedLocation = null;
let cache = { board: null, ts: 0 };

async function geocode() {
  if (ZIP_CODE) {
    const res = await fetch(`${GEOCODE_URL}?name=${ZIP_CODE}&count=1&language=en&format=json`);
    if (!res.ok) throw new Error(`Geocoding error: ${res.status}`);
    const data = await res.json();

    if (data.results?.length) {
      const { name, latitude, longitude } = data.results[0];
      return { name, latitude, longitude };
    }

    // Fall back to a US ZIP lookup when the geocoder has no match.
    const zipRes = await fetch(`${ZIP_URL}/${ZIP_CODE}`);
    if (!zipRes.ok) throw new Error(`Could not geocode ZIP: ${ZIP_CODE}`);
    const place = (await zipRes.json()).places[0];
    return {
      name: place["place name"],
      latitude: parseFloat(place.latitude),
      longitude: parseFloat(place.longitude),
    };
  }

  const res = await fetch(
    `${GEOCODE_URL}?name=${encodeURIComponent(CITY)}&count=1&language=en&format=json`,
  );
  if (!res.ok) throw new Error(`Geocoding error: ${res.status}`);
  const data = await res.json();
  if (!data.results?.length) throw new Error(`City not found: ${CITY}`);
  const { name, latitude, longitude } = data.results[0];
  return { name, latitude, longitude };
}

async function fetchWeather(latitude, longitude) {
  const url =
    `${FORECAST_URL}?latitude=${latitude}&longitude=${longitude}` +
    `&current=temperature_2m,weather_code,wind_speed_10m` +
    `&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=auto`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Weather API error: ${res.status} ${res.statusText}`);
  return res.json();
}

export function buildWeatherBoard(weather, cityName) {
  const { temperature_2m, weather_code } = weather.current;
  const temp = Math.round(temperature_2m);
  const description = WEATHER_DESCRIPTIONS[weather_code] || "WEATHER";

  return [
    centerRow(textToCharCodes(cityName.toUpperCase().slice(0, COLS))),
    centerRow(textToCharCodes(`${temp}°F`)),
    centerRow(textToCharCodes(description)),
  ];
}

/**
 * Returns a weather board, using a short-lived cache to avoid refetching on
 * every tick. Returns null if the fetch fails.
 */
export async function getWeatherBoard(nowMs = Date.now()) {
  if (cache.board && nowMs - cache.ts < WEATHER_CACHE_MS) {
    return cache.board;
  }

  try {
    cachedLocation ??= await geocode();
    const weather = await fetchWeather(cachedLocation.latitude, cachedLocation.longitude);
    const board = buildWeatherBoard(weather, cachedLocation.name);
    cache = { board, ts: nowMs };
    return board;
  } catch (err) {
    console.error("Weather fetch failed:", err.message);
    return null;
  }
}
