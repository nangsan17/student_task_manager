import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';
import '../../utils/theme.dart';
 
/// Returns a [PickedLocation] or null if cancelled.
class PickedLocation {
  final double lat, lng;
  final String address;
  const PickedLocation(
      {required this.lat, required this.lng, this.address = ''});
}
 
class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  const LocationPickerScreen({super.key, this.initialLat, this.initialLng});
  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}
 
class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _mapCtrl = MapController();
  LatLng? _picked;
  String _address = '';
  bool _locating = false;
  bool _resolving = false;
  String? _errorMsg;
 
  // Default: Kuala Lumpur
  static const _default = LatLng(3.1390, 101.6869);
 
  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _picked = LatLng(widget.initialLat!, widget.initialLng!);
    } else {
      // Auto-locate on open with permission check
      Future.delayed(const Duration(milliseconds: 300), _goToMyLocation);
    }
  }
 
  Future<void> _goToMyLocation() async {
    setState(() {
      _locating = true;
      _errorMsg = null;
    });
    try {
      // Check and request location permission
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
 
      // Handle permission results
      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locating = false;
            _errorMsg =
                'Location permission denied. Tap the map to select location or check app settings.';
            _picked = _default;
          });
          _mapCtrl.move(_default, 14);
        }
        return;
      }
 
      if (perm == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _locating = false;
            _errorMsg = 'Location permission required.';
            _picked = _default;
          });
          _mapCtrl.move(_default, 14);
        }
        return;
      }
 
      // Get current position
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
 
      final ll = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
 
      setState(() {
        _picked = ll;
        _locating = false;
        _errorMsg = null;
      });
      _mapCtrl.move(ll, 16);
      _resolveAddress(ll);
    } on LocationServiceDisabledException {
      if (mounted) {
        setState(() {
          _locating = false;
          _errorMsg =
              'Location services disabled. Enable in device settings or select manually on map.';
          _picked = _default;
        });
        _mapCtrl.move(_default, 14);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locating = false;
          _errorMsg = 'Error getting location. Tap map to select manually.';
          _picked = _default;
        });
        _mapCtrl.move(_default, 14);
      }
    }
  }
 
  Future<void> _resolveAddress(LatLng ll) async {
    if (kIsWeb) {
      if (mounted) {
        setState(() => _address =
            '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}');
      }
      return;
    }
 
    setState(() => _resolving = true);
    try {
      final marks = await placemarkFromCoordinates(ll.latitude, ll.longitude);
      if (marks.isNotEmpty && mounted) {
        final p = marks.first;
        final parts = [p.name, p.street, p.subLocality, p.locality]
            .where((s) => s != null && s!.isNotEmpty)
            .toSet()
            .toList();
        setState(() {
          _address = parts.take(3).join(', ');
          _resolving = false;
        });
      } else if (mounted) {
        setState(() {
          _address =
              '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}';
          _resolving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _address =
              '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}';
          _resolving = false;
        });
      }
    }
  }
 
  void _onMapTap(LatLng ll) {
    setState(() => _picked = ll);
    _mapCtrl.move(ll, 16);
    _resolveAddress(ll);
  }
 
  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: const Text('Pick Location'),
          actions: [
            if (_picked != null)
              CupertinoButton(
                  padding: const EdgeInsets.only(right: 12),
                  onPressed: () => Navigator.pop(
                      context,
                      PickedLocation(
                          lat: _picked!.latitude,
                          lng: _picked!.longitude,
                          address: _address)),
                  child: const Text('Done',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)))
          ]),
      body: Stack(children: [
        // Map
        FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
                initialCenter: _picked ?? _default,
                initialZoom: _picked != null ? 16.0 : 14.0,
                onTap: (_, ll) => _onMapTap(ll)),
            children: [
              TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              MarkerLayer(
                  markers: _picked != null
                      ? [
                          Marker(
                              point: _picked!,
                              width: 40,
                              height: 40,
                              child: Column(children: [
                                Icon(Icons.location_on_rounded,
                                    color: AppColors.danger, size: 32),
                              ]))
                        ]
                      : []),
            ]),
        // Bottom info card
        Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16)),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_errorMsg != null) ...[
                                Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                        color: AppColors.dangerLight,
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    child: Row(children: [
                                      const Icon(Icons.warning_rounded,
                                          color: AppColors.danger, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: Text(_errorMsg!,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.danger)))
                                    ])),
                                const SizedBox(height: 12),
                              ],
                              Row(children: [
                                Icon(Icons.location_on_rounded,
                                    color: AppColors.primary, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Selected Location',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary)),
                                          if (_locating)
                                            const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2))
                                          else if (_resolving)
                                            const Text('Getting address...',
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        AppColors.textPrimary))
                                          else if (_address.isNotEmpty)
                                            Text(_address,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color:
                                                        AppColors.textPrimary))
                                          else
                                            const Text('Tap map to select',
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: AppColors
                                                        .textSecondary))
                                        ]))
                              ]),
                              if (_picked != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                    '${_picked!.latitude.toStringAsFixed(5)}, ${_picked!.longitude.toStringAsFixed(5)}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary))
                              ]
                            ]))))),
        // Locate me button
        Positioned(
            bottom: 120,
            right: 16,
            child: FloatingActionButton(
                backgroundColor: AppColors.primary,
                onPressed: _locating ? null : _goToMyLocation,
                child: _locating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.my_location_rounded,
                        color: Colors.white)))
      ]));
}
