import 'package:flutter/material.dart';
import 'app_gif_view_io.dart'
    if (dart.library.js_interop) 'app_gif_view_web.dart' as impl;

/// Cross-platform GIF viewer that renders a native HTML `<img>` element on Web
/// (enabling proper looping GIF animations in CanvasKit/Skwasm without canvas
/// static frame freezes or memory leaks) and standard Flutter image decoding on IO.
class AppGifView extends StatelessWidget {
  const AppGifView({
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
    return impl.PlatformGifView(
      key: key,
      url: url,
      altText: altText,
      fit: fit,
      height: height,
      width: width,
      errorBuilder: errorBuilder,
    );
  }
}
