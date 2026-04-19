// ignore_for_file: empty_catches

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:resturant_delivery_boy/common/models/api_response_model.dart';
import 'package:resturant_delivery_boy/common/models/track_model.dart';
import 'package:resturant_delivery_boy/common/reposotories/tracker_repo.dart';

class TrackerProvider extends ChangeNotifier {
  final TrackerRepo? trackerRepo;
  TrackerProvider({required this.trackerRepo});

  final List<TrackModel> _trackList = [];
  final int _selectedTrackIndex = 0;
  final bool _isBlockButton = false;
  final bool _canDismiss = true;
  bool _startTrack = false;
  Timer? _timer;

  List<TrackModel> get trackList => _trackList;
  int get selectedTrackIndex => _selectedTrackIndex;
  bool get isBlockButton => _isBlockButton;
  bool get canDismiss => _canDismiss;
  bool get startTrack => _startTrack;

  int? _activeOrderId;
  DocumentReference? _firestoreDoc;

  Position? _lastPosition;
  StreamSubscription<Position>? _positionStream;
  bool get isPositionStreamActive => _positionStream != null;

  void setTrackOrderId(int? orderId) {
    _activeOrderId = orderId;
    if (_activeOrderId != null) {
      _firestoreDoc = FirebaseFirestore.instance
          .collection('tracking')
          .doc(_activeOrderId.toString());
    } else {
      _firestoreDoc = null;
    }
  }

  void stopLocationService() {
    _startTrack = false;
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
    if (kDebugMode) {
      print(
          "------------------------- Location service Stopped ----------------------- ");
    }
    notifyListeners();
  }

  void startListenCurrentLocation() {
    if (_positionStream == null) {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          distanceFilter: 10,
          accuracy: LocationAccuracy.high,
        ),
      ).listen((Position position) async {
        if (_lastPosition != null) {
          double distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );

          if (distance > 10) {
            ApiResponseModel apiResponse = await trackerRepo!
                .addTrack(lat: position.latitude, long: position.longitude);

            if (_firestoreDoc != null) {
              try {
                await _firestoreDoc!.set({
                  'latitude': position.latitude,
                  'longitude': position.longitude,
                  'heading': position.heading,
                  'driver_id':
                      1, // Optional: add actual driver id from auth or repo
                  'updated_at': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
              } catch (e) {
                if (kDebugMode) {
                  print("Error updating Firestore: $e");
                }
              }
            }

            if (kDebugMode) {
              print(
                  "Location update status on sever ---- ${apiResponse.response?.statusCode}");
            }
          }
        }
        _lastPosition = position; // Update last known position
      });

      if (kDebugMode) {
        print("Location tracking started.");
      }
    }
  }

  void stopListening() {
    _positionStream?.cancel();
    _positionStream = null;
    if (kDebugMode) {
      print("Location tracking stopped.");
    }
  }
}
