import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Cloudinary configuration. Uses **unsigned** uploads (cloud name + preset
/// only) so the app never has to ship the API secret. Values can be overridden
/// at build time with --dart-define.
abstract final class CloudinaryConfig {
  static const cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'lwakcrdc',
  );
  static const uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'nesty_unsigned',
  );

  /// Optional server endpoint that returns a signature (the web app's
  /// `/api/cloudinary-sign`). When set, uploads are SIGNED (no preset needed);
  /// otherwise they fall back to the unsigned [uploadPreset].
  static const signUrl = String.fromEnvironment('CLOUDINARY_SIGN_URL');

  static bool get isConfigured =>
      cloudName.isNotEmpty && (uploadPreset.isNotEmpty || signUrl.isNotEmpty);
}

/// A failure that carries a message safe to show the user.
class CloudinaryException implements Exception {
  const CloudinaryException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Uploads images to Cloudinary and returns their secure delivery URLs.
abstract final class Cloudinary {
  static Uri get _endpoint => Uri.parse(
    'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
  );

  static Future<String> uploadFile(File file, {String folder = 'nesty/listings'}) async {
    final bytes = await file.readAsBytes();
    final name = file.path.split(RegExp(r'[\\/]')).last;
    return uploadBytes(bytes, filename: name, folder: folder);
  }

  static Future<String> uploadBytes(
    Uint8List bytes, {
    String filename = 'upload.jpg',
    String folder = 'nesty/listings',
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      throw const CloudinaryException('Image hosting isn\'t configured.');
    }
    final request = http.MultipartRequest('POST', _endpoint)
      ..fields['folder'] = folder
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

    if (CloudinaryConfig.signUrl.isNotEmpty) {
      // Signed upload — fetch a signature from our server (secret stays there).
      final sign = await _fetchSignature(folder);
      request.fields
        ..['api_key'] = sign['apiKey'].toString()
        ..['timestamp'] = sign['timestamp'].toString()
        ..['signature'] = sign['signature'].toString();
    } else {
      // Unsigned upload with a preset.
      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
    }

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      final url = (jsonDecode(body) as Map<String, dynamic>)['secure_url'];
      if (url is String) return url;
      throw const CloudinaryException('Upload succeeded but no URL returned.');
    }
    String message = 'Upload failed (${streamed.statusCode}).';
    try {
      final err = (jsonDecode(body) as Map<String, dynamic>)['error'];
      if (err is Map && err['message'] is String) {
        message = err['message'] as String;
      }
    } catch (_) {}
    throw CloudinaryException(message);
  }

  static Future<Map<String, dynamic>> _fetchSignature(String folder) async {
    final res = await http.post(
      Uri.parse(CloudinaryConfig.signUrl),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'folder': folder}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw const CloudinaryException('Couldn\'t sign the upload.');
  }
}
