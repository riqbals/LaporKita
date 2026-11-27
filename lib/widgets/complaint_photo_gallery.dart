import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// Galeri foto pengaduan reusable (mendukung 1 hingga beberapa foto).
class ComplaintPhotoGallery extends StatelessWidget {
  const ComplaintPhotoGallery({
    super.key,
    required this.imageUrls,
    this.height = 220,
  });

  final List<String> imageUrls;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    if (imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          imageUrls.first,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _errorPlaceholder(double.infinity),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              imageUrls[index],
              width: 260,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _errorPlaceholder(260),
            ),
          );
        },
      ),
    );
  }

  Widget _errorPlaceholder(double width) {
    return Container(
      width: width,
      height: height,
      color: AppColors.divider,
      alignment: Alignment.center,
      child: const Text('Foto tidak dapat ditampilkan'),
    );
  }
}
