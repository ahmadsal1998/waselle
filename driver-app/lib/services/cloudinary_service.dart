import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class CloudinaryService {
  // These should be set via environment variables or config
  // For now, using placeholder - user should replace with their Cloudinary credentials
  static const String cloudName = 'wassle'; // Replace with your Cloudinary cloud name
  static const String uploadPreset = 'qzqtuwwn'; // Replace with your unsigned upload preset
  
  // Maximum file size in bytes (5MB)
  static const int maxFileSize = 5 * 1024 * 1024;
  
  // Allowed image types
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  /// Validates image file before upload
  /// Returns null if valid, error message if invalid
  static String? validateImage(File imageFile) {
    // Check if file exists
    if (!imageFile.existsSync()) {
      return 'Image file not found';
    }

    // Check file size
    final fileSize = imageFile.lengthSync();
    if (fileSize > maxFileSize) {
      return 'Image size exceeds 5MB limit';
    }

    if (fileSize == 0) {
      return 'Image file is empty';
    }

    // Check file extension
    final extension = path.extension(imageFile.path).toLowerCase().replaceAll('.', '');
    if (!allowedExtensions.contains(extension)) {
      return 'Invalid image type. Allowed types: ${allowedExtensions.join(", ")}';
    }

    return null; // Valid
  }

  /// Uploads image to Cloudinary
  /// Returns the image URL on success, throws exception on error
  static Future<String> uploadImage(File imageFile) async {
    // Validate image first
    final validationError = validateImage(imageFile);
    if (validationError != null) {
      throw Exception(validationError);
    }

    // Check if credentials are configured
    if (cloudName == 'YOUR_CLOUD_NAME' || uploadPreset == 'YOUR_UPLOAD_PRESET') {
      throw Exception(
        'Cloudinary credentials not configured. Please set CLOUD_NAME and UPLOAD_PRESET in cloudinary_service.dart'
      );
    }

    try {
      // Create multipart request
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload'
      );

      final request = http.MultipartRequest('POST', uri);
      
      // Add upload preset (unsigned upload)
      request.fields['upload_preset'] = uploadPreset;
      
      // Add folder for organization (optional)
      request.fields['folder'] = 'driver-profiles';
      
      // Add file
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: path.basename(imageFile.path),
      );
      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          errorBody['error']?['message'] ?? 'Failed to upload image to Cloudinary'
        );
      }

      final responseData = jsonDecode(response.body);
      final imageUrl = responseData['secure_url'] as String?;

      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception('Failed to get image URL from Cloudinary response');
      }

      return imageUrl;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error uploading image: ${e.toString()}');
    }
  }

  /// Deletes image from Cloudinary (if needed)
  /// Note: This requires signed requests with API key and secret
  static Future<void> deleteImage(String publicId) async {
    // Implementation would require API key and secret
    // For now, leaving as placeholder
    throw UnimplementedError('Delete functionality requires API key and secret');
  }
}

