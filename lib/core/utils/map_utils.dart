import 'package:google_maps_flutter/google_maps_flutter.dart';

extension LatLngBoundsUtils on LatLngBounds {
  /// Calcula o centro geográfico deste LatLngBounds.
  LatLng get center {
    return LatLng(
      (northeast.latitude + southwest.latitude) / 2,
      (northeast.longitude + southwest.longitude) / 2,
    );
  }

  /// Cria um LatLngBounds a partir de uma lista de pontos LatLng.
  static LatLngBounds fromLatLngList(List<LatLng> list) {
    if (list.isEmpty) {
      return LatLngBounds(
        northeast: const LatLng(0, 0),
        southwest: const LatLng(0, 0),
      );
    }

    double x0 = list.first.latitude,
        x1 = x0,
        y0 = list.first.longitude,
        y1 = y0;
    for (final latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }
    return LatLngBounds(northeast: LatLng(x1, y1), southwest: LatLng(x0, y0));
  }
}
