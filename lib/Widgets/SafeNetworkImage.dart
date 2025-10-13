import 'package:flutter/material.dart';

class SafeNetworkImage extends StatelessWidget {
  final String imageUrl;
  final String? fallbackAssetPath;
  final double? width;
  final double? height;
  final BoxFit fit;

  const SafeNetworkImage({
    Key? key,
    required this.imageUrl,
    this.fallbackAssetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        if (fallbackAssetPath != null) {
          return Image.asset(
            fallbackAssetPath!,
            width: width,
            height: height,
            fit: fit,
          );
        }
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.error, color: Colors.grey),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
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
    );
  }
}

class SafeCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackAssetPath;
  final double radius;
  final Color? backgroundColor;

  const SafeCircleAvatar({
    Key? key,
    this.imageUrl,
    this.fallbackAssetPath,
    required this.radius,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey[300],
        backgroundImage: fallbackAssetPath != null
            ? AssetImage(fallbackAssetPath!)
            : null,
        child: fallbackAssetPath == null
            ? Icon(Icons.person, size: radius, color: Colors.grey)
            : null,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[300],
      child: ClipOval(
        child: Image.network(
          imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return CircleAvatar(
              radius: radius,
              backgroundColor: backgroundColor ?? Colors.grey[300],
              backgroundImage: fallbackAssetPath != null
                  ? AssetImage(fallbackAssetPath!)
                  : null,
              child: fallbackAssetPath == null
                  ? Icon(Icons.person, size: radius, color: Colors.grey)
                  : null,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: radius * 2,
              height: radius * 2,
              color: backgroundColor ?? Colors.grey[300],
              child: Center(
                child: SizedBox(
                  width: radius,
                  height: radius,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}