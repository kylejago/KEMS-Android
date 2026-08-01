class HaEntity {
  const HaEntity({
    required this.entityId,
    required this.state,
    required this.attributes,
    this.lastChanged,
  });

  final String entityId;
  final String state;
  final Map<String, dynamic> attributes;
  final DateTime? lastChanged;

  factory HaEntity.fromJson(Map<String, dynamic> json) => HaEntity(
        entityId: json['entity_id'] as String? ?? '',
        state: json['state']?.toString() ?? 'unknown',
        attributes: Map<String, dynamic>.from(
          json['attributes'] as Map? ?? const <String, dynamic>{},
        ),
        lastChanged: DateTime.tryParse(json['last_changed']?.toString() ?? ''),
      );

  String get friendlyName =>
      attributes['friendly_name']?.toString() ?? entityId;

  String get unit => attributes['unit_of_measurement']?.toString() ?? '';

  double? get numericState => double.tryParse(state);
}
