import '../constants/api_constants.dart';

class ImageUrlHelper {
  /// Resolves any image URL (relative, misformed, or local) to a valid absolute URL.
  static String resolve(dynamic rawUrl) {
    if (rawUrl == null) return '';
    var url = rawUrl.toString().trim();
    if (url.isEmpty || url == 'null') return '';

    // Fix repeated storage path segments
    url = url.replaceAll('/storage//storage/', '/storage/');
    url = url.replaceAll('storage//storage/', 'storage/');

    final base = ApiConstants.baseUrl.replaceAll(RegExp(r'/+$'), '');

    if (url.startsWith('http://') || url.startsWith('https://')) {
      // Fix invalid SSL scheme on local development port 8000
      if (url.contains('https://127.0.0.1:8000')) {
        url = url.replaceFirst('https://127.0.0.1:8000', 'http://127.0.0.1:8000');
      }
      if (url.contains('https://localhost:8000')) {
        url = url.replaceFirst('https://localhost:8000', 'http://localhost:8000');
      }

      // If the app is using a remote base URL or tunnel (e.g. nexoramarket.store)
      // but the server returned localhost / 127.0.0.1, replace host with base
      if (!base.contains('127.0.0.1') && !base.contains('localhost')) {
        url = url.replaceAll(RegExp(r'https?://(127\.0\.0\.1|localhost)(:\d+)?'), base);
      } else if (base.contains('10.0.2.2')) {
        url = url.replaceAll(RegExp(r'https?://(127\.0\.0\.1|localhost)'), 'http://10.0.2.2');
      }

      return url;
    }

    // Relative path handling
    if (url.startsWith('/')) {
      return '$base$url';
    }
    return '$base/$url';
  }
}

