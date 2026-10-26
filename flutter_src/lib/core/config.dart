class AppConfig {
  static const String _defaultUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000',
  );

  static String? _overrideUrl;

  /// Sets an override URL for testing or dynamic environment switching.
  static void setApiBaseUrl(String? url) {
    _overrideUrl = url != null ? normalizeBaseUrl(url) : null;
  }

  /// Resets the API base URL back to default.
  static void resetApiBaseUrl() {
    _overrideUrl = null;
  }

  /// Returns the normalized API base URL.
  static String get apiBaseUrl => _overrideUrl ?? normalizeBaseUrl(_defaultUrl);

  /// Normalizes a given URL by trimming whitespace, removing trailing slashes,
  /// stripping redundant `/api` suffixes, and preventing accidental targeting
  /// of the Flutter web development server (e.g. port 51834).
  static String normalizeBaseUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.isEmpty) {
      return 'http://localhost:5000';
    }

    // Prevent accidentally targeting the Flutter web dev server port
    if (trimmed.contains(':51834')) {
      return 'http://localhost:5000';
    }

    // Strip trailing slashes
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }

    // Strip redundant trailing /api if provided by the environment variable
    if (trimmed.endsWith('/api')) {
      trimmed = trimmed.substring(0, trimmed.length - 4);
      while (trimmed.endsWith('/')) {
        trimmed = trimmed.substring(0, trimmed.length - 1);
      }
    }

    return trimmed.isNotEmpty ? trimmed : 'http://localhost:5000';
  }
}
