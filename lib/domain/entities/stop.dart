import 'package:flutter/foundation.dart';

/// A boardable stop/station node. Mirrors what the `GET STOPS` API returns.
@immutable
class Stop {
  const Stop({
    required this.id,
    required this.name,
    required this.city,
    this.area,
    this.latitude,
    this.longitude,
    this.isPopular = false,
  });

  final String id;
  final String name;
  final String city;
  final String? area;
  final double? latitude;
  final double? longitude;
  final bool isPopular;

  String get fullName => area == null ? '$name, $city' : '$name, $area';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Stop && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
