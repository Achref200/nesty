import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// True when [source] points at a remote URL rather than a local file path.
bool isRemoteImage(String source) =>
    switch (Uri.tryParse(source.trim())?.scheme.toLowerCase()) {
      'http' || 'https' => true,
      _ => false,
    };

/// A drop-in image that handles remote URLs on web and native and local file
/// paths on native. Keeps a soft monochrome fallback on failure.
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
    final cleanSource = source.trim();
    if (isRemoteImage(cleanSource) && kIsWeb) {
      // Listing photos are often hosted by an agency's site or an image CDN.
      // Those servers commonly allow normal <img> display but don't send CORS
      // headers, which prevents Flutter's canvas image loader from reading the
      // bytes. Prefer a browser image element on web; native keeps disk cache.
      return Image.network(
        cleanSource,
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: true,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (_, _, _) => const _Fallback(),
      );
    }
    if (isRemoteImage(cleanSource)) {
      return CachedNetworkImage(
        imageUrl: cleanSource,
        fit: fit,
        width: width,
        height: height,
        placeholder: (_, _) => const ColoredBox(color: AppColors.fill),
        errorWidget: (_, _, _) => const _Fallback(),
      );
    }
    if (kIsWeb && cleanSource.startsWith('blob:')) {
      return Image.network(
        cleanSource,
        fit: fit,
        width: width,
        height: height,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (_, _, _) => const _Fallback(),
      );
    }
    if (kIsWeb || cleanSource.isEmpty) return const _Fallback();
    return Image.file(
      File(cleanSource),
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
