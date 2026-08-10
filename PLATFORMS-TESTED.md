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

| Platform            | Status     | Notes                                                                                                                                                                                              |
| ------------------- | ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Google Home         | Worked     | Direct commissioning works and Google Home shows the full measurement set. When the device is commissioned in SmartThings and shared to Google Home, Google Home currently shows only temperature. |
| Home Assistant      | Worked     | Google Home-first test: commission in Google Home, then share the Matter device to Home Assistant. Full measurement data is visible.                                                               |
| Apple Home          | Not tested |                                                                                                                                                                                                    |
| Amazon Alexa        | Not tested |                                                                                                                                                                                                    |
| Samsung SmartThings | Worked     | Direct commissioning works and full PurpleAir measurement data is visible. Sharing a device commissioned in Google Home to SmartThings also preserves the full measurement set.                    |

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

## Cross-controller sharing workflows

The plugin publishes the canonical Matter `AirQualitySensor` device type
with the Air Quality, Temperature Measurement, Relative Humidity Measurement,
Pressure Measurement, PM1, PM2.5, PM10, and optional TVOC clusters on the same
endpoint. The endpoint implementation and automated tests verify those
clusters; the values are not omitted from the Matter device.

The plugin publishes the canonical Matter `AirQualitySensor` device type
with the Air Quality, Temperature Measurement, Relative Humidity Measurement,
Pressure Measurement, PM1, PM2.5, PM10, and optional TVOC clusters on the same
endpoint. The endpoint implementation and automated tests verify those
clusters; the values are not omitted from the Matter device.

Two sharing workflows were tested:

### SmartThings first, then Google Home

1. Commission the PurpleAir Matterbridge in Samsung SmartThings.
2. Confirm that SmartThings displays the broader measurement set.
3. Use SmartThings' sharing or multi-admin flow to share the Matter device to
   Google Home.
4. Open the shared device in Google Home.

On Android 17, SmartThings displayed the air quality, temperature, humidity,
and particulate measurements, while Google Home displayed only temperature
for the shared device. This is a controller-side capability/presentation
limitation in the SmartThings-to-Google-Home sharing path.

### Google Home first, then SmartThings

1. Commission the PurpleAir Matterbridge directly in Google Home.
2. Confirm that Google Home displays the full measurement set.
3. Use Google Home's linked Matter app or multi-admin flow to share the Matter
   device to Samsung SmartThings.
4. Open the device in SmartThings.

In this direction, both Google Home and SmartThings displayed the full
measurement set, including temperature, humidity, air quality, pressure, and
particulate measurements.

### Google Home first, then Home Assistant

1. Commission the PurpleAir Matterbridge directly in Google Home.
2. Confirm that Google Home displays the full measurement set.
3. Use Google Home's linked Matter app or multi-admin flow to share the Matter
   device to Home Assistant.
4. Open the device in Home Assistant.

This workflow also completed successfully. Home Assistant displayed the full
measurement set, including temperature, humidity, air quality, pressure, and
particulate measurements.

These results show that the limitation is direction-dependent and belongs to
the SmartThings-to-Google-Home sharing path, not to the Matterbridge endpoint
or the PurpleAir data feed. The same Matter endpoint can provide the full
measurement set to multiple controllers when Google Home is the commissioning
controller.

Do not factory-reset or split the readings into synthetic Matter endpoints to
work around the first sharing result. Synthetic endpoints could create
duplicate or misleading devices. Use the Google-Home-first sharing workflow
when both controllers need the full measurement set.
