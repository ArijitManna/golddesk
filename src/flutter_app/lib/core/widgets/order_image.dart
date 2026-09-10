import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

/// Opens a full-screen zoomable image viewer (pinch / double-tap / pan).
void showZoomableOrderImage(
  BuildContext context, {
  required ImageProvider image,
  String? label,
}) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (ctx) => _ZoomableOrderImageDialog(image: image, label: label),
  );
}

void showZoomableOrderImageUrl(
  BuildContext context, {
  required String imageUrl,
  String? label,
}) {
  showZoomableOrderImage(
    context,
    image: NetworkImage(imageUrl),
    label: label,
  );
}

void showZoomableOrderImagePath(
  BuildContext context, {
  required String imagePath,
  String? label,
}) {
  showZoomableOrderImageUrl(
    context,
    imageUrl: '${AppConstants.serverUrl}$imagePath',
    label: label,
  );
}

class _ZoomableOrderImageDialog extends StatefulWidget {
  final ImageProvider image;
  final String? label;

  const _ZoomableOrderImageDialog({required this.image, this.label});

  @override
  State<_ZoomableOrderImageDialog> createState() =>
      _ZoomableOrderImageDialogState();
}

class _ZoomableOrderImageDialogState extends State<_ZoomableOrderImageDialog> {
  final _transformationController = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final position = _doubleTapDetails?.localPosition;
    if (position == null) return;

    final matrix = _transformationController.value;
    final isZoomed = matrix.getMaxScaleOnAxis() > 1.05;
    if (isZoomed) {
      _transformationController.value = Matrix4.identity();
      return;
    }

    const zoom = 2.5;
    final x = -position.dx * (zoom - 1);
    final y = -position.dy * (zoom - 1);
    _transformationController.value = Matrix4.identity()
      ..translate(x, y)
      ..scale(zoom);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onDoubleTapDown: (details) => _doubleTapDetails = details,
              onDoubleTap: _handleDoubleTap,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Image(
                    image: widget.image,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: 200,
                      height: 200,
                      color: AppColors.surface,
                      alignment: Alignment.center,
                      child: const Text('Image not available'),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryDark,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ),
          if (widget.label != null)
            Positioned(
              bottom: 28,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.label!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class OrderImage extends StatelessWidget {
  final String? imagePath;
  final double size;
  final String? label;

  const OrderImage({super.key, this.imagePath, this.size = 44, this.label});

  String get _fullUrl => '${AppConstants.serverUrl}$imagePath';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: imagePath != null
          ? () => showZoomableOrderImagePath(
                context,
                imagePath: imagePath!,
                label: label,
              )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imagePath != null
            ? Image.network(
                _fullUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Icon(
        Icons.diamond_outlined,
        color: AppColors.gold,
        size: size * 0.45,
      ),
    );
  }
}
