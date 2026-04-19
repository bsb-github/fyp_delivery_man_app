import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:resturant_delivery_boy/common/providers/tracker_provider.dart';
import 'package:resturant_delivery_boy/common/widgets/custom_app_bar_widget.dart';
import 'package:resturant_delivery_boy/features/order/domain/models/order_model.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel orderModel;

  const OrderTrackingScreen({Key? key, required this.orderModel})
      : super(key: key);

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  late TrackerProvider _trackerProvider;
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints =
      PolylinePoints(apiKey: "AIzaSyBvRwrEMwSptfokcyagWqGCCcxz_05PRK0");
  StreamSubscription<Position>? _positionSubscription;
  LocationSettings locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );

  LatLng? _currentPosition;
  late LatLng _destinationPosition;

  @override
  void initState() {
    super.initState();
    _trackerProvider = Provider.of<TrackerProvider>(context, listen: false);
    _destinationPosition = LatLng(
      double.tryParse('${widget.orderModel.deliveryAddress?.latitude}') ?? 0.0,
      double.tryParse('${widget.orderModel.deliveryAddress?.longitude}') ?? 0.0,
    );
    _setCurrentLocation();

    // Set order ID in tracker provider so it pushes to Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _trackerProvider.setTrackOrderId(widget.orderModel.id);
      }
    });
  }

  @override
  void dispose() {
    _trackerProvider.setTrackOrderId(null);
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _setCurrentLocation() async {
    bool isGranted = await _checkPermission();
    if (!isGranted) {
      debugPrint("Permission not granted. Maps might not load correctly.");
      setState(() {
        _currentPosition = _destinationPosition;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _updateMarkersAndPolylines();
      });

      _mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentPosition!, zoom: 14),
      ));
    } catch (e) {
      debugPrint("Error fetching initial location: $e");
      // Fallback if unable to fetch location immediately
      setState(() {
        _currentPosition = _destinationPosition;
      });
    }

    _startListeningLocationUpdates();
  }

  void _startListeningLocationUpdates() {
    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _updateMarkersAndPolylines();
      });
    });
  }

  Future<bool> _checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> _updateMarkersAndPolylines() async {
    if (_currentPosition == null) return;

    _markers = {
      Marker(
        markerId: const MarkerId("delivery_man"),
        position: _currentPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        infoWindow: const InfoWindow(title: "You"),
      ),
      Marker(
        markerId: const MarkerId("destination"),
        position: _destinationPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: "Delivery Location"),
      ),
    };

    // Replace with your Google Maps API Key to fetch accurate polylines
    // Alternatively, draw a straight line if API key is not yet set up for Directions API
    try {
      RoutesApiResponse result =
          await polylinePoints.getRouteBetweenCoordinatesV2(
              request: RoutesApiRequest(
        origin: PointLatLng(
            _currentPosition!.latitude, _currentPosition!.longitude),
        destination: PointLatLng(
            _destinationPosition.latitude, _destinationPosition.longitude),
        travelMode: TravelMode.driving,
      ));
      log("Polyline result: ${result.routes.length} routes found");

      if (result.routes.isNotEmpty) {
        polylineCoordinates.clear();
        for (var point in result.routes.first.polylinePoints!) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }

        Polyline polyline = Polyline(
          polylineId: const PolylineId("route"),
          color: Theme.of(context).primaryColor,
          points: polylineCoordinates,
          width: 5,
        );
        setState(() {
          _polylines.add(polyline);
        });
      } else {
        // Fallback to straight line
        _polylines.add(Polyline(
          polylineId: const PolylineId("straight_route"),
          color: Theme.of(context).primaryColor,
          points: [_currentPosition!, _destinationPosition],
          width: 5,
        ));
      }
    } catch (e) {
      debugPrint("Polyline error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarWidget(title: 'Order Tracking'),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition ?? _destinationPosition,
                zoom: 14.0,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
            ),
    );
  }
}
