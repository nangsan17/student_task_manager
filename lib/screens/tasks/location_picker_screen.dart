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

  // Default: Kuala Lumpur (matches user's coordinates from screenshots)
  static const _default = LatLng(3.1390, 101.6869);

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _picked = LatLng(widget.initialLat!, widget.initialLng!);
    } else {
      // Auto-locate on open
      Future.delayed(const Duration(milliseconds: 300), _goToMyLocation);
    }
  }

  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locating = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high));
      final ll = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _picked = ll;
        _locating = false;
      });
      _mapCtrl.move(ll, 16);
      _resolveAddress(ll);
    } catch (_) {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _resolveAddress(LatLng ll) async {
    if (kIsWeb) {
      // Geocoding doesn't work on web — show coordinates instead
      if (mounted)
        setState(() => _address =
            '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}');
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
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _address =
              '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}';
          _resolving = false;
        });
    }
  }

  void _onTap(TapPosition _, LatLng ll) {
    setState(() {
      _picked = ll;
      _address = '';
    });
    _resolveAddress(ll);
  }

  void _confirm() {
    if (_picked == null) return;
    Navigator.pop(
        context,
        PickedLocation(
            lat: _picked!.latitude,
            lng: _picked!.longitude,
            address: _address));
  }

  @override
  Widget build(BuildContext context) {
    final center = _picked ?? _default;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pin Your Location'),
        leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            child:
                const Icon(Icons.close_rounded, color: AppColors.textPrimary)),
        actions: [
          CupertinoButton(
              padding: const EdgeInsets.only(right: 12),
              onPressed: _picked != null ? _confirm : null,
              child: Text('Done',
                  style: TextStyle(
                      color: _picked != null
                          ? AppColors.primary
                          : AppColors.textHint,
                      fontWeight: FontWeight.w700,
                      fontSize: 16))),
        ],
      ),
      body: Stack(children: [
        // Map — OpenStreetMap tiles, no API key, works everywhere
        FlutterMap(
          mapController: _mapCtrl,
          options: MapOptions(
            initialCenter: center,
            initialZoom: _picked != null ? 16 : 12,
            onTap: _onTap,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.student_task_manager',
            ),
            if (_picked != null)
              MarkerLayer(markers: [
                Marker(
                  point: _picked!,
                  width: 48,
                  height: 56,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                            color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.place_rounded,
                            color: Colors.white, size: 22)),
                    CustomPaint(
                        size: const Size(12, 8), painter: _DropShadowPainter()),
                  ]),
                ),
              ]),
          ],
        ),

        // Info card at bottom
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.12), blurRadius: 14)
                  ]),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selected Location',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    if (_locating)
                      const Row(children: [
                        CupertinoActivityIndicator(),
                        SizedBox(width: 10),
                        Text('Getting your location…',
                            style: TextStyle(fontSize: 14))
                      ])
                    else if (_resolving)
                      const Row(children: [
                        CupertinoActivityIndicator(),
                        SizedBox(width: 10),
                        Text('Finding address…', style: TextStyle(fontSize: 14))
                      ])
                    else if (_picked == null)
                      const Text('Tap anywhere on the map to pin your location',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textHint))
                    else
                      Row(children: [
                        const Icon(Icons.location_on_rounded,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                            child: Text(
                                _address.isNotEmpty
                                    ? _address
                                    : '${_picked!.latitude.toStringAsFixed(5)}, ${_picked!.longitude.toStringAsFixed(5)}',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary))),
                      ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                          child: OutlinedButton.icon(
                              onPressed: _locating ? null : _goToMyLocation,
                              icon: const Icon(Icons.my_location_rounded,
                                  size: 16),
                              label: const Text('My Location'),
                              style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12))))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: ElevatedButton(
                              onPressed: _picked != null ? _confirm : null,
                              style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12))),
                              child: const Text('Confirm'))),
                    ]),
                  ])),
        ),
      ]),
    );
  }
}

class _DropShadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.width,
            height: size.height),
        Paint()..color = AppColors.primary.withOpacity(0.25));
  }

  @override
  bool shouldRepaint(_) => false;
}
