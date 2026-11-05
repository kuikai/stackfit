import 'package:shelf/shelf.dart';

import 'share_store.dart';

const _siteName = 'StackFit';
const _fallbackDescription = 'Custom workouts. Clean timers.';

/// Chat apps read these tags without running JavaScript, so a pasted /s/ link
/// only shows the workout name if the server writes them into the page.
String withSharePreview(String indexHtml, Request request, StoredShare? share) {
  final base = '${request.requestedUri.scheme}://${request.requestedUri.authority}';
  final title = _previewTitle(share);
  final tags = [
    _meta('property', 'og:type', 'website'),
    _meta('property', 'og:site_name', _siteName),
    _meta('property', 'og:title', title),
    _meta('property', 'og:description', _previewDescription(share)),
    _meta('property', 'og:url', '$base/${request.url.path}'),
    _meta('property', 'og:image', '$base/icons/app-icon-512.png'),
    _meta('name', 'twitter:card', 'summary'),
    _meta('name', 'description', _previewDescription(share)),
  ].join('\n    ');
  final pageTitle = share == null ? _siteName : '${_escape(title)} · $_siteName';
  return indexHtml
      .replaceFirst('<title>$_siteName</title>', '<title>$pageTitle</title>')
      .replaceFirst('</head>', '  $tags\n  </head>');
}

String _previewTitle(StoredShare? share) {
  if (share == null) {
    return _siteName;
  }
  if (share.kind == 'progress') {
    return 'Training progress';
  }
  final name = share.body['name'];
  return name is String && name.trim().isNotEmpty ? name.trim() : 'Shared workout';
}

String _previewDescription(StoredShare? share) {
  if (share == null) {
    return _fallbackDescription;
  }
  if (share.kind == 'progress') {
    final sessions = share.body['sessions'];
    final count = sessions is List ? sessions.length : 0;
    return '${count == 1 ? '1 session' : '$count sessions'} shared from StackFit.';
  }
  final names = _exerciseNames(share.body['exercises']);
  if (names.isEmpty) {
    return 'A workout shared from StackFit.';
  }
  final count = names.length == 1 ? '1 exercise' : '${names.length} exercises';
  final shown = names.take(4).join(', ');
  final more = names.length > 4 ? ' and ${names.length - 4} more' : '';
  return '$count: $shown$more. Open it in StackFit.';
}

List<String> _exerciseNames(Object? raw) {
  if (raw is! List) {
    return const [];
  }
  return [
    for (final exercise in raw)
      if (exercise is Map && exercise['name'] is String) (exercise['name'] as String).trim(),
  ];
}

String _meta(String attribute, String key, String value) {
  return '<meta $attribute="$key" content="${_escape(value)}">';
}

String _escape(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
