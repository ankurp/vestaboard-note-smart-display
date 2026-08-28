import { CHARS, centerRow, textToCharCodes } from "./display.js";

/** The default "idle" board: a message plus the weekday and date. */

const DAYS = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];

export function buildClockBoard(now = new Date()) {
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  const year = String(now.getFullYear());

  return [
    centerRow(textToCharCodes("KITCHEN IS THE")),
    centerRow([CHARS.HEART, ...textToCharCodes(" OF THE HOME")]),
    centerRow(textToCharCodes(`${DAYS[now.getDay()]} ${month}/${day}/${year}`)),
  ];
}
