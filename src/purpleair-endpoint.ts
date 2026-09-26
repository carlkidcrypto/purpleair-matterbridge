import { MatterbridgeEndpoint, airQualitySensor } from "matterbridge";
import {
  AirQuality,
  Pm1ConcentrationMeasurement,
  Pm10ConcentrationMeasurement,
  Pm25ConcentrationMeasurement,
  PressureMeasurement,
  RelativeHumidityMeasurement,
  TemperatureMeasurement,
  TotalVolatileOrganicCompoundsConcentrationMeasurement,
} from "matterbridge/matter/clusters";

import type { PurpleAirReading } from "./purpleair-client.js";

interface Breakpoint {
  concLow: number;
  concHigh: number;
  aqiLow: number;
  aqiHigh: number;
}

const BREAKPOINTS: readonly Breakpoint[] = [
  { concLow: 0.0, concHigh: 12.0, aqiLow: 0, aqiHigh: 50 },
  { concLow: 12.1, concHigh: 35.4, aqiLow: 51, aqiHigh: 100 },
  { concLow: 35.5, concHigh: 55.4, aqiLow: 101, aqiHigh: 150 },
  { concLow: 55.5, concHigh: 150.4, aqiLow: 151, aqiHigh: 200 },
  { concLow: 150.5, concHigh: 250.4, aqiLow: 201, aqiHigh: 300 },
  { concLow: 250.5, concHigh: 350.4, aqiLow: 301, aqiHigh: 400 },
  { concLow: 350.5, concHigh: 500.4, aqiLow: 401, aqiHigh: 500 },
];

/**
 * Convert PM2.5 concentration (µg/m³) to EPA AQI.
 * Uses EPA breakpoint table and linear interpolation. Caps at 500.
 */
export function pm25ToAqi(pm25: number): number {
  if (pm25 <= 0) return 0;
  if (pm25 >= 500.4) return 500;
  const bp =
    BREAKPOINTS.find((b) => pm25 >= b.concLow && pm25 <= b.concHigh) ??
    BREAKPOINTS[BREAKPOINTS.length - 1]!;
  const { concLow, concHigh, aqiLow, aqiHigh } = bp;
  const aqi = ((aqiHigh - aqiLow) / (concHigh - concLow)) * (pm25 - concLow) + aqiLow;
  return Math.round(Math.min(aqi, 500));
}

const MAC_ADDRESS_PATTERN = /^(?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2}$/i;

export function purpleAirDeviceName(sensorName: string): string {
  if (!MAC_ADDRESS_PATTERN.test(sensorName)) return sensorName;
  return `purple-air-${sensorName.toLowerCase().split(/[:-]/).slice(-3).join("-")}`;
}

export function purpleAirSerialNumber(sensorIndex: string): string {
  return `purpleair-${sensorIndex}`;
}

export function createPurpleAirEndpoint(
  reading: PurpleAirReading,
  vendorId: number,
): MatterbridgeEndpoint {
  const deviceName = purpleAirDeviceName(reading.sensorName);
  const serialNumber = purpleAirSerialNumber(reading.sensorIndex);
  const endpoint = new MatterbridgeEndpoint(airQualitySensor, { id: serialNumber })
    .createDefaultBridgedDeviceBasicInformationClusterServer(
      deviceName,
      serialNumber,
      vendorId,
      "PurpleAir",
      "PurpleAir Air Quality Sensor",
      undefined,
      reading.firmwareVersion,
    )
    .createDefaultAirQualityClusterServer(pm25ToAqi(reading.pm25 ?? 0) as AirQuality.AirQualityEnum)
    .createDefaultTemperatureMeasurementClusterServer(reading.temperature ?? null)
    .createDefaultRelativeHumidityMeasurementClusterServer(reading.humidity ?? null)
    .createDefaultPressureMeasurementClusterServer(reading.pressure ?? null)
    .createDefaultPm1ConcentrationMeasurementClusterServer(reading.pm1 ?? null)
    .createDefaultPm25ConcentrationMeasurementClusterServer(reading.pm25 ?? null)
    .createDefaultPm10ConcentrationMeasurementClusterServer(reading.pm10 ?? null);

  if (reading.tvoc !== undefined) endpoint.createDefaultTvocMeasurementClusterServer(reading.tvoc);
  return endpoint.addRequiredClusters();
}

export async function updatePurpleAirEndpoint(
  endpoint: MatterbridgeEndpoint,
  reading: PurpleAirReading,
): Promise<void> {
  const updates: Promise<boolean>[] = [
    endpoint.updateAttribute(
      AirQuality,
      "airQuality",
      reading.airQuality as AirQuality.AirQualityEnum,
    ),
  ];

  if (reading.temperature !== undefined)
    updates.push(
      endpoint.updateAttribute(TemperatureMeasurement, "measuredValue", reading.temperature),
    );
  if (reading.humidity !== undefined)
    updates.push(
      endpoint.updateAttribute(RelativeHumidityMeasurement, "measuredValue", reading.humidity),
    );
  if (reading.pressure !== undefined)
    updates.push(endpoint.updateAttribute(PressureMeasurement, "measuredValue", reading.pressure));
  if (reading.pm1 !== undefined)
    updates.push(
      endpoint.updateAttribute(Pm1ConcentrationMeasurement, "measuredValue", reading.pm1),
    );
  if (reading.pm25 !== undefined)
    updates.push(
      endpoint.updateAttribute(Pm25ConcentrationMeasurement, "measuredValue", reading.pm25),
    );
  if (reading.pm10 !== undefined)
    updates.push(
      endpoint.updateAttribute(Pm10ConcentrationMeasurement, "measuredValue", reading.pm10),
    );
  if (
    reading.tvoc !== undefined &&
    endpoint.hasClusterServer(TotalVolatileOrganicCompoundsConcentrationMeasurement)
  ) {
    updates.push(
      endpoint.updateAttribute(
        TotalVolatileOrganicCompoundsConcentrationMeasurement,
        "measuredValue",
        reading.tvoc,
      ),
    );
  }

  await Promise.all(updates);
}
