import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_map/const/consts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Location _locationController = new Location();
  LatLng? _currentP = null;

  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  static const LatLng _ahd = LatLng(23.0225, 72.5714);
  static const LatLng _rjt = LatLng(22.3039, 70.8022);

  Map<PolylineId, Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    getLocationUpdates().then(
      (_) => getPolyLinePoints().then(
        (coordinates) {
          generatePolylineFromPoints(coordinates);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentP == null
          ? const Center(
              child: Text("Loading..."),
            )
          : GoogleMap(
              onMapCreated: (GoogleMapController controller) =>
                  _mapController.complete(controller),
              initialCameraPosition:
                  const CameraPosition(target: _ahd, zoom: 13),
              markers: <Marker>{
                Marker(
                    markerId: const MarkerId(
                      "_currentLocation",
                    ),
                    icon: BitmapDescriptor.defaultMarker,
                    position: _currentP!),
                const Marker(
                    markerId: MarkerId(
                      "_sourceLocation",
                    ),
                    icon: BitmapDescriptor.defaultMarker,
                    position: _ahd),
                const Marker(
                    markerId: MarkerId(
                      "_destinationLocation",
                    ),
                    icon: BitmapDescriptor.defaultMarker,
                    position: _rjt),
              },
              polylines: Set<Polyline>.of(polylines.values),
            ),
    );
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition _newCameraPosition = CameraPosition(
      target: pos,
      zoom: 13,
    );
    await controller
        .animateCamera(CameraUpdate.newCameraPosition(_newCameraPosition));
  }

  Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    // Check if service is enabled
    _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      // Request service to be enabled if not already enabled
      _serviceEnabled = await _locationController.requestService();
      if (!_serviceEnabled) {
        // Return if the service is still not enabled
        return;
      }
    }

    // Check permission status
    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      // Request permission if it was denied earlier
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        // Return if permission is still denied
        return;
      }
    }

    // Start listening for location updates
    _locationController.onLocationChanged.listen(
      (LocationData currentLocation) {
        if (currentLocation.latitude != null &&
            currentLocation.longitude != null) {
          setState(() {
            _currentP =
                LatLng(currentLocation.latitude!, currentLocation.longitude!);
            _cameraToPosition(_currentP!);
            print(_currentP); // Logging the current position
          });
        }
      },
    );
  }

  Future<List<LatLng>> getPolyLinePoints() async {
    List<LatLng> polylineCordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult polylineResult =
        await polylinePoints.getRouteBetweenCoordinates(
            request: PolylineRequest(
                origin: PointLatLng(_rjt.latitude, _rjt.longitude),
                destination: PointLatLng(_ahd.latitude, _ahd.longitude),
                mode: TravelMode.driving),
            googleApiKey: GOOGLE_MAP_API_KEY);
    if (polylineResult.points.isNotEmpty) {
      polylineResult.points.forEach(
        (PointLatLng point) {
          polylineCordinates.add(LatLng(point.latitude, point.longitude));
        },
      );
    } else {
      print(polylineResult.errorMessage);
    }
    return polylineCordinates;
  }

  void generatePolylineFromPoints(List<LatLng> polylineCordinates) async {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.black,
        points: polylineCordinates,
        width: 8); 
        setState(() {
          polylines[id] = polyline;
        });
  }
}
