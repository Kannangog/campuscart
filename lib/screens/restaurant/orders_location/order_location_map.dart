// ignore_for_file: deprecated_member_use, avoid_print

import 'dart:async';
import 'dart:ui' as ui;
import 'package:campuscart/models/order_model.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class OrdersLocationMap extends StatefulWidget {
  final List<OrderModel> orders;
  final LatLng restaurantLocation;
  final Function(GoogleMapController) onMapCreated;
  final Function(OrderModel) onOrderSelected;

  const OrdersLocationMap({
    super.key,
    required this.orders,
    required this.restaurantLocation,
    required this.onMapCreated,
    required this.onOrderSelected,
  });

  @override
  State<OrdersLocationMap> createState() => _OrdersLocationMapState();
}

class _OrdersLocationMapState extends State<OrdersLocationMap> {
  final Set<Marker> _markers = {};
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _currentLocation;
  BitmapDescriptor? _activeOrderIcon;
  BitmapDescriptor? _deliveredOrderIcon;
  BitmapDescriptor? _currentLocationIcon;
  BitmapDescriptor? _restaurantIcon;
  bool _locationPermissionGranted = false;
  bool _isLocationLoading = true;
  bool _isOrdersCardExpanded = false;
  StreamSubscription<Position>? _positionStream;
  final Map<String, BitmapDescriptor> _customerIcons = {};

  @override
  void initState() {
    super.initState();
    _createCustomMarkers();
    _requestLocationPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMarkers();
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  // Create custom marker icons with precise positioning
  Future<void> _createCustomMarkers() async {
    // Use default markers as fallback
    _activeOrderIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    _deliveredOrderIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    _currentLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    _restaurantIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    
    // Try to create custom markers with larger sizes
    try {
      // Create custom current location marker (larger size)
      final currentLocationIcon = await _createCustomMarker(
        color: const ui.Color.fromARGB(255, 17, 140, 56),
        icon: Icons.local_shipping,
        size: 90, // Increased from 48 to 70
      );

      // Create custom restaurant marker (larger size)
      final restaurantIcon = await _createCustomMarker(
        color: Colors.red,
        icon: Icons.restaurant,
        size: 80, // Increased from 60 to 80
      );

      // Create custom order markers (larger sizes)
      final activeOrderIcon = await _createCustomMarker(
        color: const ui.Color.fromARGB(255, 213, 56, 56),
        icon: Icons.person_pin_circle,
        size: 100, // Increased from 50 to 70
      );

      final deliveredOrderIcon = await _createCustomMarker(
        color: Colors.blue,
        icon: Icons.check_circle,
        size: 70, // Increased from 50 to 70
      );

      setState(() {
        _currentLocationIcon = currentLocationIcon;
        _restaurantIcon = restaurantIcon;
        _activeOrderIcon = activeOrderIcon;
        _deliveredOrderIcon = deliveredOrderIcon;
      });
    } catch (e) {
      print("Error creating custom markers: $e");
      // Fallback to default markers
      setState(() {});
    }
  }

  Future<BitmapDescriptor> _createCustomMarker({
    required Color color,
    required IconData icon,
    required double size,
  }) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw marker background
    final radius = size / 2;
    canvas.drawCircle(Offset(radius, radius), radius, paint);

    // Draw white border
    canvas.drawCircle(
      Offset(radius, radius),
      radius - 3, // Slightly thicker border
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3, // Increased from 2 to 3
    );

    // Draw icon
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size * 0.6,
        fontFamily: icon.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(radius - textPainter.width / 2, radius - textPainter.height / 2),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  // Create customer marker icon
  Future<BitmapDescriptor> createCustomerMarkerIcon({
    required String imageUrl,
    required String orderId,
    required bool isDelivered,
  }) async {
    // Check if we already have this icon cached
    if (_customerIcons.containsKey(orderId)) {
      return _customerIcons[orderId]!;
    }

    try {
      const double size = 100.0;
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      
      // Draw background circle with status color
      final Paint backgroundPaint = Paint()
        ..color = isDelivered ? Colors.blue : Colors.green;
      
      // Draw shadow
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2,
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      
      // Draw background
      canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 2, backgroundPaint);
      
      // Draw white border
      canvas.drawCircle(
        const Offset(size / 2, size / 2),
        size / 2 - 4,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      
      // Draw status indicator
      if (!isDelivered) {
        canvas.drawCircle(
          const Offset(size - 15, 15),
          8,
          Paint()
            ..color = Colors.orange
            ..style = PaintingStyle.fill,
        );
      }

      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

      final descriptor = BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
      
      // Cache the icon
      _customerIcons[orderId] = descriptor;
      
      return descriptor;
    } catch (e) {
      print("Error creating customer marker: $e");
      return isDelivered ? _deliveredOrderIcon! : _activeOrderIcon!;
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("Location services are disabled");
        setState(() {
          _isLocationLoading = false;
        });
        _showLocationServiceDisabledDialog();
        return;
      }

      // Check location permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("Location permissions are denied");
          setState(() {
            _isLocationLoading = false;
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print("Location permissions are permanently denied");
        setState(() {
          _isLocationLoading = false;
        });
        _showLocationPermissionPermanentlyDeniedDialog();
        return;
      }

      // Permission granted
      setState(() {
        _locationPermissionGranted = true;
      });
      
      // Start listening to location updates instead of one-time fetch
      _startLocationListening();
      
    } catch (e) {
      print("Error requesting location permission: $e");
      setState(() {
        _isLocationLoading = false;
      });
    }
  }

  void _startLocationListening() {
    if (!_locationPermissionGranted) return;

    // Cancel any existing stream
    _positionStream?.cancel();

    // Start listening to location updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen(
      (Position position) {
        print("Location update: ${position.latitude}, ${position.longitude}");
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLocationLoading = false;
        });
        _updateMarkers();
      },
      onError: (e) {
        print("Error in location stream: $e");
        setState(() {
          _isLocationLoading = false;
        });
        
        // Try to restart the stream with lower accuracy
        if (e is LocationServiceDisabledException) {
          _showLocationServiceDisabledDialog();
        } else {
          // Try again with lower accuracy
          _positionStream = Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              distanceFilter: 50,
            ),
          ).listen(
            (Position position) {
              setState(() {
                _currentLocation = LatLng(position.latitude, position.longitude);
                _isLocationLoading = false;
              });
              _updateMarkers();
            },
            onError: (e) {
              print("Error in fallback location stream: $e");
              setState(() {
                _isLocationLoading = false;
              });
            },
          );
        }
      },
    );

    // Also get an immediate position
    _getImmediateLocation();
  }

  Future<void> _getImmediateLocation() async {
    try {
      // Get a quick position with lower accuracy
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(const Duration(seconds: 5));

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLocationLoading = false;
      });
      _updateMarkers();
    } catch (e) {
      print("Error getting immediate location: $e");
      // Don't set loading to false here - the stream will handle updates
    }
  }

  void _showLocationServiceDisabledDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Location Services Disabled"),
          content: const Text("Please enable location services in your device settings to see your accurate position on the map."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
              child: const Text("Open Settings"),
            ),
          ],
        );
      },
    );
  }

  void _showLocationPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Location Permission Required"),
          content: const Text("Location permissions are permanently denied. Please enable them in app settings for accurate delivery tracking."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openAppSettings();
              },
              child: const Text("App Settings"),
            ),
          ],
        );
      },
    );
  }

  @override
  void didUpdateWidget(covariant OrdersLocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.orders != widget.orders) {
      _updateMarkers();
    }
  }

  Future<void> _updateMarkers() async {
    _markers.clear();
    
    // Add current location marker if available
    if (_currentLocation != null && _currentLocationIcon != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: _currentLocationIcon!,
          infoWindow: const InfoWindow(title: 'Your Current Location'),
          zIndex: 4,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }
    
    // Add restaurant location marker
    if (_restaurantIcon != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('restaurant'),
          position: widget.restaurantLocation,
          icon: _restaurantIcon!,
          infoWindow: const InfoWindow(title: 'Restaurant Location'),
          zIndex: 3,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }
    
    // Add order markers with customer icons
    for (var order in widget.orders) {
      final double lat = order.deliveryLatitude;
      final double lng = order.deliveryLongitude;
      
      // Skip invalid coordinates
      if (lat == 0.0 && lng == 0.0) continue;
      
      final bool isDelivered = order.status == OrderStatus.delivered;
      
      // Create custom marker icon using the CustomerMarker widget
      final BitmapDescriptor icon = await createCustomerMarkerIcon(
        imageUrl: order.foodImageUrl ?? '', // Provide a default value if null
        orderId: order.id,
        isDelivered: isDelivered,
      );
      
      final marker = Marker(
        markerId: MarkerId(order.id),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: 'Order #${order.id.substring(0, 8)}',
          snippet: '${order.userName} - ${_getStatusText(order.status)}',
        ),
        icon: icon,
        onTap: () {
          widget.onOrderSelected(order);
          _animateToPosition(LatLng(lat, lng));
        },
        zIndex: isDelivered ? 1 : 2,
        anchor: const Offset(0.5, 0.5),
      );
      
      _markers.add(marker);
    }
    
    setState(() {});
  }

  Future<void> _animateToPosition(LatLng position) async {
    final controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(position, 17),
    );
  }

  Future<void> _centerOnCurrentLocation() async {
    if (_currentLocation != null) {
      final controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 17),
      );
    } else if (_locationPermissionGranted && !_isLocationLoading) {
      // Try to get current location if not available
      try {
        await _getImmediateLocation();
      } catch (e) {
        print("Error getting current location: $e");
      }
    }
  }

  Future<void> _focusOnOrder(OrderModel order) async {
    final double lat = order.deliveryLatitude;
    final double lng = order.deliveryLongitude;
    
    // Skip invalid coordinates
    if (lat == 0.0 && lng == 0.0) return;
    
    // Animate to the order location
    await _animateToPosition(LatLng(lat, lng));
    
    // Show the order info window
    final markerId = MarkerId(order.id);
    final controller = await _controller.future;
    
    // This will show the info window for the marker
    controller.showMarkerInfoWindow(markerId);
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for Delivery';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      default:
        return 'Unknown';
    }
  }

  void _refreshLocation() async {
    setState(() {
      _isLocationLoading = true;
    });
    
    // Get fresh location
    await _getImmediateLocation();
  }

  void _toggleOrdersCard() {
    setState(() {
      _isOrdersCardExpanded = !_isOrdersCardExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders = widget.orders.where((o) => o.status != OrderStatus.delivered).length;
    
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.restaurantLocation,
            zoom: 15,
          ),
          markers: _markers,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            widget.onMapCreated(controller);
          },
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
        ),
        
        // Floating map controls
        Positioned(
          right: 16,
          bottom: 120,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'current_location',
                onPressed: _centerOnCurrentLocation,
                backgroundColor: Colors.white,
                child: Icon(Icons.my_location, color: Theme.of(context).primaryColor),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'refresh_location',
                onPressed: _refreshLocation,
                backgroundColor: Colors.white,
                child: _isLocationLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.refresh, color: Theme.of(context).primaryColor),
              ),
            ],
          ),
        ),
        
        // Orders summary overlay with toggle functionality
        Positioned(
          top: 16,
          left: 16,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 160,
              constraints: BoxConstraints(
                maxHeight: _isOrdersCardExpanded 
                    ? MediaQuery.of(context).size.height * 0.5
                    : 36,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with toggle button
                  GestureDetector(
                    onTap: _toggleOrdersCard,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.delivery_dining, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Orders ($activeOrders)',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            _isOrdersCardExpanded 
                                ? Icons.keyboard_arrow_up 
                                : Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Content that expands/collapses
                  if (_isOrdersCardExpanded) _buildOrdersContent(),
                ],
              ),
            ),
          ),
        ),

        // Location status overlay
        if (!_locationPermissionGranted || _isLocationLoading)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            left: 20,
            right: 20,
            child: _buildLocationStatusOverlay(),
          ),
      ],
    );
  }

  Widget _buildOrdersContent() {
    final preparingOrders = widget.orders.where((o) => o.status == OrderStatus.preparing).length;
    final readyOrders = widget.orders.where((o) => o.status == OrderStatus.ready).length;
    final outForDeliveryOrders = widget.orders.where((o) => o.status == OrderStatus.outForDelivery).length;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.3,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusIndicator(
              color: Colors.blue,
              count: preparingOrders,
              label: 'Preparing',
              isFullWidth: true,
              isSmall: true,
            ),
            const SizedBox(height: 4),
            _StatusIndicator(
              color: Colors.orange,
              count: readyOrders,
              label: 'Ready',
              isFullWidth: true,
              isSmall: true,
            ),
            const SizedBox(height: 4),
            _StatusIndicator(
              color: Colors.green,
              count: outForDeliveryOrders,
              label: 'Out for Delivery',
              isFullWidth: true,
              isSmall: true,
            ),
            const SizedBox(height: 8),
            // Add focus buttons for each order
            ...widget.orders.where((order) => order.status != OrderStatus.delivered).map((order) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: ElevatedButton(
                  onPressed: () => _focusOnOrder(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.grey.shade800,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 30),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Order #${order.id.substring(0, 6)}',
                          style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStatusOverlay() {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLocationLoading)
              const Column(
                children: [
                  SizedBox(height: 8),
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    "Getting your location...",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              )
            else if (!_locationPermissionGranted)
              Column(
                children: [
                  const Icon(Icons.location_off, size: 40, color: Colors.orange),
                  const SizedBox(height: 8),
                  const Text(
                    "Location Access Required",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Enable location to see your position",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _requestLocationPermission,
                    child: const Text("Enable Location"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final Color color;
  final int count;
  final String label;
  final bool isFullWidth;
  final bool isSmall;

  const _StatusIndicator({
    required this.color,
    required this.count,
    required this.label,
    this.isFullWidth = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: isSmall 
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSmall ? 10 : 12,
            height: isSmall ? 10 : 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: isSmall ? 12 : 16,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: isSmall ? 10 : 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}