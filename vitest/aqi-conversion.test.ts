import { describe, expect, test } from "vitest";
import { pm25ToAqi } from "../src/purpleair-endpoint.js";

describe("pm25ToAqi conversion", () => {
  test.each([
    [0, 0],
    [10, 42],
    [25, 78],
    [200, 250],
    [600, 500],
  ])("pm25 %i => AQI %i", (pm25, expected) => {
    expect(pm25ToAqi(pm25)).toBe(expected);
  });
});
