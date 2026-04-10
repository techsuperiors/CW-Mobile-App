import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubePostContent {
  final String url;
  final String videoId;
  final String textWithoutUrl;

  const YoutubePostContent({
    required this.url,
    required this.videoId,
    required this.textWithoutUrl,
  });
}

class YoutubePostContentResolver {
  YoutubePostContentResolver._();

  static final RegExp _urlRegExp = RegExp(
    r'(https?:\/\/[^\s]+)',
    caseSensitive: false,
  );

  static YoutubePostContent? resolve(String description) {
    final trimmedDescription = description.trim();
    if (trimmedDescription.isEmpty) return null;

    final matches = _urlRegExp.allMatches(trimmedDescription);
    for (final match in matches) {
      final url = match.group(0);
      if (url == null || url.isEmpty) continue;

      final videoId = YoutubePlayer.convertUrlToId(url);
      if (videoId == null || videoId.isEmpty) continue;

      final textWithoutUrl = trimmedDescription
          .replaceFirst(url, '')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();

      return YoutubePostContent(
        url: url,
        videoId: videoId,
        textWithoutUrl: textWithoutUrl,
      );
    }

    return null;
  }
}
