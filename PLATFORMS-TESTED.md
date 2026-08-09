# Platforms tested

This document tracks Matter controller platforms tested with
`purpleair-matterbridge`. A successful result applies only to the environment
tested and does not guarantee compatibility with every platform version or
network configuration.

## Status definitions

- **Worked**: Commissioning and basic use completed successfully.
- **In progress**: Testing started, but end-to-end operation is not yet
  confirmed.
- **Not tested**: No result has been recorded.

## Compatibility matrix

| Platform            | Status      | Notes                                                                                                                  |
| ------------------- | ----------- | ---------------------------------------------------------------------------------------------------------------------- |
| Google Home         | Worked      | Test path: commission in Samsung SmartThings, then share the Matter device to Google Home. Google Home currently exposes only temperature for this bridged Air Quality Sensor. |
| Home Assistant      | In progress | Matterbridge commissioning reached an Android Local Fabric, but the Home Assistant handoff has not yet been confirmed. |
| Apple Home          | Not tested  |                                                                                                                        |
| Amazon Alexa        | Not tested  |                                                                                                                        |
| Samsung SmartThings | Worked      | Full PurpleAir measurement data is visible, including air quality, temperature, humidity, and particulate measurements. |

## Details to record

When adding a test result, include when available:

- Controller application and version
- Controller or hub hardware
- Mobile operating system and version
- Matterbridge and plugin versions
- Network topology
- Commissioning result
- PurpleAir endpoints and attributes exposed by the controller
- Known limitations or required workarounds

## Google Home entity limitation

The plugin publishes the canonical Matter ``AirQualitySensor`` device type
with the Air Quality, Temperature Measurement, Relative Humidity Measurement,
Pressure Measurement, PM1, PM2.5, PM10, and optional TVOC clusters on the same
endpoint. The endpoint implementation and automated tests verify those
clusters; the values are not omitted from the Matter device.

The tested sequence was:

1. Commission the PurpleAir Matterbridge in Samsung SmartThings.
2. Confirm that SmartThings displays the broader measurement set.
3. Use SmartThings' sharing or multi-admin flow to share the Matter device to
  Google Home.
4. Open the shared device in Google Home.

On Android 17, SmartThings displayed the air quality, temperature, humidity,
and particulate measurements, while Google Home displayed only temperature
for the shared device. This is a controller-side capability/presentation
limitation in the SmartThings-to-Google-Home sharing path: Google Home does
not currently expose all of the concentration, pressure, humidity, and
air-quality attributes supplied by this bridged endpoint.

Do not factory-reset or re-pair the device to solve this presentation issue.
Use SmartThings or a Matter controller with support for the additional
measurement clusters when those values are needed. Splitting the readings into
separate synthetic Matter endpoints could create duplicate or misleading
devices and would not be a reliable Google Home fix.
