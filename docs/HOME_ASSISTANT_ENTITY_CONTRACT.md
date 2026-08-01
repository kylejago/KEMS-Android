# KEMS Home Assistant entity contract

KEMS Companion 0.2 targets the entity contract observed in **KEMS integration 0.6.0-alpha1**.
Home Assistant remains the source of truth. The app reads `sensor.kems_*` and
`binary_sensor.kems_*` entities via the REST and WebSocket APIs.

## Current integration phase

The current integration reports `sensor.kems_phase` as `Observe → Learn`.
Consequently, this app release is read-only. It does not assume that unsupported
selects, switches, buttons, or `kems.*` services exist.

## Primary entities

- `sensor.kems_status`
- `sensor.kems_phase`
- `sensor.kems_advice`
- `sensor.kems_data_quality`
- `sensor.kems_learning_confidence`
- `binary_sensor.kems_learning_ready`
- `sensor.kems_grid_import`
- `sensor.kems_grid_export`
- `sensor.kems_grid_net_power`
- `sensor.kems_grid_flow_direction`
- `sensor.kems_house_load`
- `sensor.kems_current_import_rate`
- `sensor.kems_next_import_rate`
- `binary_sensor.kems_off_peak`
- `binary_sensor.kems_intelligent_slot`
- `binary_sensor.kems_cheap_period_confirmed`
- `binary_sensor.kems_grid_import_outside_cheap_period`
- `sensor.kems_ev_charging_power`
- `sensor.kems_ev_state_of_charge`
- `binary_sensor.kems_ev_connected`
- `binary_sensor.kems_ev_charging`

## Simulation, gas, whole-home, and ROI

The app also understands the integration's simulation, gas, whole-home, lifetime,
and ROI entities. Missing or unavailable values are shown as em dashes rather than
being replaced with data from vendor integrations.

## Forward compatibility

The settings screen discovers every `sensor.kems_*` and
`binary_sensor.kems_*` entity at runtime. New diagnostic entities therefore appear
without a new app build. Interactive controls should only be added after the KEMS
integration publishes a documented control contract.
