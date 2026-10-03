import 'package:video_player/video_player.dart';

/// Creates a video controller for a bundled asset or a public network demo.
/// Shared catalog defaults use `asset://` to identify bundled media.
VideoPlayerController exerciseVideoController(String source) {
  const assetPrefix = 'asset://';
  if (source.startsWith(assetPrefix)) {
    return VideoPlayerController.asset(source.substring(assetPrefix.length));
  }
  return VideoPlayerController.networkUrl(Uri.parse(source));
}
