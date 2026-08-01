import 'package:flutter_test/flutter_test.dart';
import 'package:kems_companion/models/entity_mapping.dart';
import 'package:kems_companion/models/ha_entity.dart';

void main() {
  test('parses a Home Assistant KEMS entity', () {
    final entity = HaEntity.fromJson({
      'entity_id': 'sensor.kems_grid_import',
      'state': '0.556',
      'attributes': {'unit_of_measurement': 'kW', 'friendly_name': 'KEMS Grid import'},
    });
    expect(entity.entityId, 'sensor.kems_grid_import');
    expect(entity.state, '0.556');
    expect(entity.unit, 'kW');
  });

  test('mapping targets KEMS 0.6 entity names', () {
    const mapping = EntityMapping();
    expect(mapping.houseLoad, 'sensor.kems_house_load');
    expect(mapping.phase, 'sensor.kems_phase');
    expect(mapping.cheapPeriodConfirmed, 'binary_sensor.kems_cheap_period_confirmed');
  });
}
