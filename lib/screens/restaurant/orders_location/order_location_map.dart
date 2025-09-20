// ignore_for_file: deprecated_member_use

import 'dart:async';
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
  StreamSubscription<Position>? _positionSubscription;
  bool _isTrackingLocation = false;

  @override
  void initState() {
    super.initState();
    _updateMarkers();
  }

  @override
  void didUpdateWidget(covariant OrdersLocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orders != widget.orders || 
        oldWidget.restaurantLocation != widget.restaurantLocation) {
      _updateMarkers();
    }
  }

  void _updateMarkers() {
    _markers.clear();
    
    // Add restaurant marker (YELLOW)
    _markers.add(
      Marker(
        markerId: const MarkerId('restaurant'),
        position: widget.restaurantLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow: const InfoWindow(
          title: 'Restaurant Location',
          snippet: 'Order pickup point',
        ),
        zIndex: 3,
      ),
    );
    
    // Add order markers with different colors based on status
    for (var order in widget.orders) {
      final double lat = order.deliveryLatitude;
      final double lng = order.deliveryLongitude;
      
      // Skip invalid coordinates
      if (lat == 0.0 && lng == 0.0) continue;
      
      final marker = Marker(
        markerId: MarkerId(order.id),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(
          title: 'Order #${order.id.substring(0, 8)}',
          snippet: '${order.userName} - ${_getStatusText(order.status)}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerHue(order.status)),
        onTap: () {
          widget.onOrderSelected(order);
          _animateToPosition(LatLng(lat, lng));
        },
        zIndex: 1,
      );
      
      _markers.add(marker);
    }
    
    setState(() {});
  }

  double _getMarkerHue(OrderStatus status) {
    switch (status) {
      case OrderStatus.preparing:
        return BitmapDescriptor.hueBlue; // Blue for preparing
      case OrderStatus.ready:
        return BitmapDescriptor.hueOrange; // Orange for ready
      case OrderStatus.outForDelivery:
        return BitmapDescriptor.hueGreen; // Green for out for delivery
      case OrderStatus.delivered:
        return BitmapDescriptor.hueViolet; // Violet for delivered
      default:
        return BitmapDescriptor.hueRed; // Red for unknown
    }
  }

  Future<void> _animateToPosition(LatLng position) async {
    final controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(position, 15),
    );
  }

  Future<void> _centerOnRestaurant() async {
    final controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(widget.restaurantLocation, 15),
    );
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

  LatLngBounds _getMapBounds() {
    final points = <LatLng>[
      widget.restaurantLocation,
      ...widget.orders
          .where((order) => order.deliveryLatitude != 0.0 && order.deliveryLongitude != 0.0)
          .map((order) => LatLng(order.deliveryLatitude, order.deliveryLongitude)),
    ];

    if (points.isEmpty) {
      return LatLngBounds(
        northeast: widget.restaurantLocation,
        southwest: widget.restaurantLocation,
      );
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _fitAllMarkers() async {
    final bounds = _getMapBounds();
    final controller = await _controller.future;
    
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100), // 100px padding
    );
  }

  Future<void> _toggleLocationTracking() async {
    if (_isTrackingLocation) {
      _positionSubscription?.cancel();
      setState(() => _isTrackingLocation = false);
      return;
    }

    final status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      final newStatus = await Geolocator.requestPermission();
      if (newStatus != LocationPermission.whileInUse && 
          newStatus != LocationPermission.always) {
        return;
      }
    }
    
    if (status == LocationPermission.deniedForever) {
      return;
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 50, // Update every 50 meters for better performance
      ),
    ).listen((Position position) {
      // We're not showing current location marker per requirements
      // but we could use this for other purposes if needed
    });

    setState(() => _isTrackingLocation = true);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map section
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.restaurantLocation,
            zoom: 14,
          ),
          markers: _markers,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            widget.onMapCreated(controller);
            
            // Fit all markers after map is created
            Future.delayed(const Duration(milliseconds: 500), _fitAllMarkers);
          },
          myLocationEnabled: false, // Disabled as per requirements
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
        ),
        
        // Floating map controls
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            children: [
              // Fit all markers button
              FloatingActionButton.small(
                heroTag: 'fit_all',
                onPressed: _fitAllMarkers,
                child: const Icon(Icons.zoom_out_map),
              ),
              const SizedBox(height: 8),
              // Restaurant location button
              FloatingActionButton.small(
                heroTag: 'restaurant',
                onPressed: _centerOnRestaurant,
                child: const Icon(Icons.restaurant),
              ),
              const SizedBox(height: 8),
              // Location tracking toggle
              FloatingActionButton.small(
                heroTag: 'location_tracking',
                onPressed: _toggleLocationTracking,
                backgroundColor: _isTrackingLocation 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.surface,
                child: Icon(
                  Icons.location_searching,
                  color: _isTrackingLocation 
                      ? Theme.of(context).colorScheme.onPrimary 
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        
        // Orders summary overlay
        if (widget.orders.isNotEmpty)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Orders: ${widget.orders.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _StatusIndicator(
                          color: Colors.blue,
                          count: widget.orders.where((o) => o.status == OrderStatus.preparing).length,
                          label: 'Preparing',
                        ),
                        _StatusIndicator(
                          color: Colors.orange,
                          count: widget.orders.where((o) => o.status == OrderStatus.ready).length,
                          label: 'Ready',
                        ),
                        _StatusIndicator(
                          color: Colors.green,
                          count: widget.orders.where((o) => o.status == OrderStatus.outForDelivery).length,
                          label: 'Delivery',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final Color color;
  final int count;
  final String label;

  const _StatusIndicator({
    required this.color,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text('$count $label'),
      ],
    );
  }
}