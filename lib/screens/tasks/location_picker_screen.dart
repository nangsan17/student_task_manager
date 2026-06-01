import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../models/task_model.dart';
import '../../utils/theme.dart';

class LocationPickerScreen extends StatefulWidget {
  final TaskLocation? initial;
  const LocationPickerScreen({super.key, this.initial});
  @override State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapCtrl;
  LatLng? _picked;
  String _address = '';
  bool _locating = false;
  bool _resolving = false;

  static const _defaultLatLng = LatLng(3.1390, 101.6869); // KL default

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      _picked  = LatLng(widget.initial!.lat, widget.initial!.lng);
      _address = widget.initial!.address;
    } else {
      _goToCurrentLocation();
    }
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final perm = await Geolocator.checkPermission();
      LocationPermission finalPerm = perm;
      if (perm == LocationPermission.denied) {
        finalPerm = await Geolocator.requestPermission();
      }
      if (finalPerm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locating = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      final ll = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() { _picked = ll; _locating = false; });
      _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(ll, 16));
      _resolveAddress(ll);
    } catch (_) {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _resolveAddress(LatLng ll) async {
    setState(() => _resolving = true);
    try {
      final placemarks = await placemarkFromCoordinates(ll.latitude, ll.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final parts = [p.name, p.street, p.subLocality, p.locality]
            .where((s) => s != null && s.isNotEmpty).toSet().toList();
        setState(() { _address = parts.take(3).join(', '); _resolving = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _address = '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}'; _resolving = false; });
    }
  }

  void _onTap(LatLng ll) {
    setState(() { _picked = ll; _address = ''; });
    _resolveAddress(ll);
  }

  void _confirm() {
    if (_picked == null) return;
    Navigator.pop(context, TaskLocation(lat: _picked!.latitude, lng: _picked!.longitude, address: _address));
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initial != null
        ? LatLng(widget.initial!.lat, widget.initial!.lng)
        : _defaultLatLng;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pin Location'),
        leading: CupertinoButton(padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(Icons.close_rounded, color: AppColors.textPrimary)),
        actions: [
          CupertinoButton(padding: const EdgeInsets.only(right: 12),
            onPressed: _picked != null ? _confirm : null,
            child: Text('Done', style: TextStyle(
                color: _picked != null ? AppColors.primary : AppColors.textHint,
                fontWeight: FontWeight.w700, fontSize: 16))),
        ],
      ),
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: initial, zoom: 15),
          onMapCreated: (c) {
            _mapCtrl = c;
            if (_picked != null) c.animateCamera(CameraUpdate.newLatLngZoom(_picked!, 16));
          },
          onTap: _onTap,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: _picked != null
              ? {Marker(markerId: const MarkerId('picked'), position: _picked!,
                  infoWindow: InfoWindow(title: _address.isNotEmpty ? _address : 'Selected location'))}
              : {},
        ),

        // Address card at bottom
        Positioned(left: 16, right: 16, bottom: 24,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12)]),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Selected Location', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              if (_locating)
                const Row(children: [CupertinoActivityIndicator(), SizedBox(width: 8),
                  Text('Getting your location...', style: TextStyle(fontSize: 14))])
              else if (_resolving)
                const Row(children: [CupertinoActivityIndicator(), SizedBox(width: 8),
                  Text('Finding address...', style: TextStyle(fontSize: 14))])
              else if (_picked == null)
                const Text('Tap anywhere on the map to pin a location',
                    style: TextStyle(fontSize: 14, color: AppColors.textHint))
              else
                Row(children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text(
                    _address.isNotEmpty ? _address
                        : '${_picked!.latitude.toStringAsFixed(5)}, ${_picked!.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
                ]),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity,
                child: Row(children: [
                  Expanded(child: OutlinedButton.icon(
                    onPressed: _locating ? null : _goToCurrentLocation,
                    icon: const Icon(Icons.my_location_rounded, size: 16),
                    label: const Text('My Location'))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(
                    onPressed: _picked != null ? _confirm : null,
                    child: const Text('Confirm'),
                  )),
                ])),
            ])),
        ),

        // My location FAB
        Positioned(right: 16, bottom: 180,
          child: FloatingActionButton.small(
            heroTag: 'loc',
            backgroundColor: Colors.white,
            onPressed: _locating ? null : _goToCurrentLocation,
            child: _locating
                ? const CupertinoActivityIndicator()
                : const Icon(Icons.my_location_rounded, color: AppColors.primary))),
      ]),
    );
  }
}
