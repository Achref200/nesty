import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// True when [source] points at a remote URL rather than a local file path.
bool isRemoteImage(String source) =>
    source.startsWith('http://') || source.startsWith('https://');

/// An [ImageProvider] that transparently handles both remote URLs (cached) and
/// on-device file paths — so listings created with imported photos render the
/// same way as curated ones. Use in [DecorationImage].
ImageProvider appImageProvider(String source) => isRemoteImage(source)
    ? CachedNetworkImageProvider(source)
    : FileImage(File(source));

/// A drop-in image that renders remote URLs via [CachedNetworkImage] and local
/// file paths via [Image.file]. Keeps a soft monochrome fallback on failure.
class AppImage extends StatelessWidget {
  const AppImage(
    this.source, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String source;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (isRemoteImage(source)) {
      return CachedNetworkImage(
        imageUrl: source,
        fit: fit,
        width: width,
        height: height,
        placeholder: (_, _) => const ColoredBox(color: AppColors.fill),
        errorWidget: (_, _, _) => const _Fallback(),
      );
    }
    return Image.file(
      File(source),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, _, _) => const _Fallback(),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.fill,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.secondaryLabel,
          size: 28,
        ),
      ),
    );
  }
}
