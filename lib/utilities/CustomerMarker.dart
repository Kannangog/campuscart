import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// CustomerMarker widget for displaying food order images in circular avatars
class CustomerMarker extends StatelessWidget {
  final String imageUrl;
  final double size;
  final String orderId;
  final bool isDelivered;

  const CustomerMarker({
    super.key,
    required this.imageUrl,
    required this.orderId,
    this.isDelivered = false,
    this.size = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDelivered ? Colors.green : Colors.orange,
          width: 3.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Food image
          ClipOval(
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.fastfood,
                          color: Colors.grey[600],
                          size: size * 0.5,
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.fastfood,
                      color: Colors.grey[600],
                      size: size * 0.5,
                    ),
                  ),
          ),
          
          // Delivery status indicator
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDelivered ? Colors.green : Colors.orange,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDelivered ? Icons.check : Icons.delivery_dining,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function to create a bitmap descriptor from the CustomerMarker widget
Future<BitmapDescriptor> createCustomerMarkerIcon({
  required String imageUrl,
  required String orderId,
  required bool isDelivered,
  double size = 80.0,
}) async {
  try {
    // Create a repaint boundary
    final RenderRepaintBoundary boundary = RenderRepaintBoundary();
    
    // Create a widget with explicit size
    final Widget widget = SizedBox(
      width: size,
      height: size,
      child: CustomerMarker(
        imageUrl: imageUrl,
        orderId: orderId,
        isDelivered: isDelivered,
        size: size,
      ),
    );

    // Use a simpler approach with WidgetsBinding to render the widget
    final BuildOwner buildOwner = BuildOwner();
    final PipelineOwner pipelineOwner = PipelineOwner();
    
    // Create a root element
    final Element rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: widget,
      ),
    ).attachToRenderTree(buildOwner);
    
    // Schedule a build and wait for it to complete
    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();
    
    // Trigger a layout and paint
    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    // Wait for the next frame to ensure rendering is complete
    await WidgetsBinding.instance.endOfFrame;
    
    // Convert to image
    final ui.Image image = await boundary.toImage(pixelRatio: WidgetsBinding.instance.window.devicePixelRatio * 2);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      throw Exception('Failed to convert widget to image');
    }

    return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
  } catch (e) {
    debugPrint('Error creating custom marker: $e');
    // Fallback to default marker
    return BitmapDescriptor.defaultMarkerWithHue(
      isDelivered ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
    );
  }
}