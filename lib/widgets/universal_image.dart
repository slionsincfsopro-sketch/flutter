import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UniversalImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  final Widget Function(BuildContext)? errorBuilder;

  const UniversalImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
  });
  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(context);
    }

    // Check if Network
    if (imageUrl!.startsWith('http')) {
      return Image.network(
        imageUrl!,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade50,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
      );
    }

    // Check if Base64
    final cleanedUrl = imageUrl!.trim();
    if (cleanedUrl.length > 30 && !cleanedUrl.startsWith('http') && !cleanedUrl.contains(' ')) {
       // Check for common base64 patterns or just try decoding
       try {
         // Handle potential Data URI prefix
         String base64Data = cleanedUrl;
         if (cleanedUrl.contains(',')) {
           base64Data = cleanedUrl.split(',').last;
         }
         
         return Image.memory(
           base64Decode(base64Data),
           fit: fit,
           width: width,
           height: height,
           errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
         );
       } catch (e) { 
         // Not valid base64, fall through
       }
    }

    // Local File Path
    if (!kIsWeb) {
      return Image.file(
        File(imageUrl!),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
      );
    }

    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (errorBuilder != null) return errorBuilder!(context);
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Icon(Icons.image, color: Colors.grey.shade400, size: 40),
    );
  }
}
