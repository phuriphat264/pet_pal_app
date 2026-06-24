// Hotel images used to always be local asset paths. Now that partners can
// upload real photos (stored in MinIO and served over http), a hotel's
// image list can contain a mix of both -- this picks the right widget.
import 'package:flutter/material.dart';

class PetPalImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const PetPalImage({super.key, required this.path, this.fit = BoxFit.cover, this.errorBuilder});

  bool get _isNetwork => path.startsWith('http://') || path.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (_isNetwork) {
      return Image.network(
        path,
        fit: fit,
        width: double.infinity,
        errorBuilder: errorBuilder,
      );
    }
    return Image.asset(
      path,
      fit: fit,
      width: double.infinity,
      errorBuilder: errorBuilder,
    );
  }
}
