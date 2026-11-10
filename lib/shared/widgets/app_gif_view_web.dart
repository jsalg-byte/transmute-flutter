import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:web/web.dart' as web;

class PlatformGifView extends StatefulWidget {
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
  State<PlatformGifView> createState() => _PlatformGifViewState();
}

class _PlatformGifViewState extends State<PlatformGifView> {
  bool _hasError = false;

  @override
  void didUpdateWidget(PlatformGifView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _hasError = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError && widget.errorBuilder != null) {
      return widget.errorBuilder!(context);
    }

    final objectFit = switch (widget.fit) {
      BoxFit.cover => 'cover',
      BoxFit.fill => 'fill',
      BoxFit.fitWidth => 'contain',
      BoxFit.fitHeight => 'contain',
      BoxFit.none => 'none',
      BoxFit.scaleDown => 'scale-down',
      BoxFit.contain => 'contain',
    };

    return SizedBox(
      height: widget.height ?? 220,
      width: widget.width ?? double.infinity,
      child: HtmlElementView.fromTagName(
        key: ValueKey('gif_${widget.url}'),
        tagName: 'img',
        hitTestBehavior: PlatformViewHitTestBehavior.transparent,
        onElementCreated: (Object element) {
          final img = element as web.HTMLImageElement;
          img.src = widget.url;
          if (widget.altText != null) {
            img.alt = widget.altText!;
          }
          img.style.width = '100%';
          img.style.height = '100%';
          img.style.objectFit = objectFit;
          img.style.display = 'block';
          img.style.pointerEvents = 'none';
          img.onerror = ((web.Event _) {
            if (mounted) {
              setState(() => _hasError = true);
            }
          }).toJS;
        },
      ),
    );
  }
}
