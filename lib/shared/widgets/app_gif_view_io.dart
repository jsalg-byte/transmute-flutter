import 'package:flutter/material.dart';

class PlatformGifView extends StatelessWidget {
  const PlatformGifView({
    super.key,
    required this.url,
    this.altText,
    this.fit = BoxFit.contain,
    this.height,
    this.width,
    this.errorBuilder,
  });

  final String url;
  final String? altText;
  final BoxFit fit;
  final double? height;
  final double? width;
  final WidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: Image.network(
        url,
        fit: fit,
        semanticLabel: altText,
        errorBuilder: (context, error, stackTrace) {
          if (errorBuilder != null) {
            return errorBuilder!(context);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
