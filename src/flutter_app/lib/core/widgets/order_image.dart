import 'package:flutter/material.dart';
import '../../data/repositories/order_repository.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../di/injection.dart';

/// Opens a full-screen zoomable image viewer (pinch / double-tap / pan).
void showZoomableOrderImage(
  BuildContext context, {
  required ImageProvider image,
  String? label,
}) {
  showOrderImageGallery(context, images: [image], label: label);
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

/// Full-screen viewer that swipes between images; each image is zoomable.
void showOrderImageGallery(
  BuildContext context, {
  required List<ImageProvider> images,
  int initialIndex = 0,
  String? label,
}) {
  if (images.isEmpty) return;
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (ctx) => _OrderImageGalleryDialog(
      images: images,
      initialIndex: initialIndex.clamp(0, images.length - 1),
      label: label,
    ),
  );
}

void showOrderImageGalleryPaths(
  BuildContext context, {
  required List<String> imagePaths,
  int initialIndex = 0,
  String? label,
}) {
  showOrderImageGallery(
    context,
    images: imagePaths
        .map((p) => NetworkImage('${AppConstants.serverUrl}$p'))
        .toList(),
    initialIndex: initialIndex,
    label: label,
  );
}

/// Loads every image of an order (all items, primary first) and opens the
/// gallery. Falls back to [fallbackPath] if the order can't be loaded.
Future<void> showOrderImagesForOrder(
  BuildContext context, {
  required String orderId,
  String? fallbackPath,
  String? label,
}) async {
  List<String> paths = [];
  try {
    final detail = await getIt<OrderRepository>().getOrderById(orderId);
    paths = detail.items.expand((i) => i.imagePaths).toList();
  } catch (_) {
    // Fall back to the thumbnail image below.
  }
  if (paths.isEmpty && fallbackPath != null) paths = [fallbackPath];
  if (paths.isEmpty || !context.mounted) return;
  showOrderImageGalleryPaths(context, imagePaths: paths, label: label);
}

class _OrderImageGalleryDialog extends StatefulWidget {
  final List<ImageProvider> images;
  final int initialIndex;
  final String? label;

  const _OrderImageGalleryDialog({
    required this.images,
    required this.initialIndex,
    this.label,
  });

  @override
  State<_OrderImageGalleryDialog> createState() =>
      _OrderImageGalleryDialogState();
}

class _OrderImageGalleryDialogState extends State<_OrderImageGalleryDialog> {
  late final PageController _pageController;
  late int _index;
  bool _zoomed = false;

  /// Fingers currently on screen. Paging must stop as soon as a second finger
  /// lands, otherwise the PageView's drag wins the gesture and pinch never zooms.
  int _pointers = 0;

  void _onPointerDown(PointerDownEvent _) {
    _pointers++;
    if (_pointers == 2) setState(() {});
  }

  void _onPointerUp(PointerEvent _) {
    if (_pointers > 0) _pointers--;
    if (_pointers == 1) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.images.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.images.length;
    final multiple = count > 1;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerUp,
              child: PageView.builder(
                controller: _pageController,
                physics: !multiple || _zoomed || _pointers >= 2
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                itemCount: count,
                onPageChanged: (i) => setState(() {
                  _index = i;
                  _zoomed = false;
                }),
                itemBuilder: (_, i) => _ZoomableImagePage(
                  image: widget.images[i],
                  onZoomChanged: (z) {
                    if (z != _zoomed) setState(() => _zoomed = z);
                  },
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
          if (multiple) ...[
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_index + 1} / $count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_index > 0)
              Align(
                alignment: Alignment.centerLeft,
                child: _navButton(Icons.chevron_left, () => _goTo(_index - 1)),
              ),
            if (_index < count - 1)
              Align(
                alignment: Alignment.centerRight,
                child: _navButton(Icons.chevron_right, () => _goTo(_index + 1)),
              ),
          ],
          Positioned(
            bottom: 28,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (multiple)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        count,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _index ? 18 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? AppColors.gold
                                : Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (widget.label != null)
                  Container(
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryDark.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _ZoomableImagePage extends StatefulWidget {
  final ImageProvider image;
  final ValueChanged<bool> onZoomChanged;

  const _ZoomableImagePage({required this.image, required this.onZoomChanged});

  @override
  State<_ZoomableImagePage> createState() => _ZoomableImagePageState();
}

class _ZoomableImagePageState extends State<_ZoomableImagePage> {
  final _transformationController = TransformationController();
  TapDownDetails? _doubleTapDetails;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final zoomed = _transformationController.value.getMaxScaleOnAxis() > 1.05;
    if (zoomed != _zoomed) {
      setState(() => _zoomed = zoomed);
      widget.onZoomChanged(zoomed);
    }
  }

  void _handleDoubleTap() {
    final position = _doubleTapDetails?.localPosition;
    if (position == null) return;

    if (_zoomed) {
      _transformationController.value = Matrix4.identity();
      return;
    }

    const zoom = 2.5;
    final x = -position.dx * (zoom - 1);
    final y = -position.dy * (zoom - 1);
    _transformationController.value = Matrix4.identity()
      ..translateByDouble(x, y, 0, 1)
      ..scaleByDouble(zoom, zoom, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapDetails = details,
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1,
        maxScale: 5,
        panEnabled: _zoomed,
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
    );
  }
}

/// Small "+N" overlay used on thumbnails when an order has more images.
class MoreImagesBadge extends StatelessWidget {
  final int extraCount;
  final double fontSize;

  const MoreImagesBadge({super.key, required this.extraCount, this.fontSize = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '+$extraCount',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      ),
    );
  }
}

class OrderImage extends StatelessWidget {
  final String? imagePath;
  final double size;
  final String? label;

  /// Total images on the order; shows a "+N" badge when more than one.
  final int imageCount;

  /// When set and [imageCount] > 1, tapping opens every image of the order.
  final String? orderId;

  const OrderImage({
    super.key,
    this.imagePath,
    this.size = 44,
    this.label,
    this.imageCount = 0,
    this.orderId,
  });

  String get _fullUrl => '${AppConstants.serverUrl}$imagePath';

  void _open(BuildContext context) {
    if (imageCount > 1 && orderId != null) {
      showOrderImagesForOrder(
        context,
        orderId: orderId!,
        fallbackPath: imagePath,
        label: label,
      );
      return;
    }
    showZoomableOrderImagePath(context, imagePath: imagePath!, label: label);
  }

  @override
  Widget build(BuildContext context) {
    final extra = imageCount - 1;
    return GestureDetector(
      onTap: imagePath != null ? () => _open(context) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imagePath != null
            ? Stack(
                children: [
                  Image.network(
                    _fullUrl,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  ),
                  if (extra > 0)
                    Positioned(
                      right: 3,
                      bottom: 3,
                      child: MoreImagesBadge(
                        extraCount: extra,
                        fontSize: size >= 50 ? 11 : 9,
                      ),
                    ),
                ],
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
