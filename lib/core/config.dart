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
  /// stripping redundant `/api` suffixes, and ensuring proper scheme.
  static String normalizeBaseUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.isEmpty) {
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

    // Ensure scheme if missing e.g. "localhost:5000" or "127.0.0.1:5000"
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }

    return trimmed.isNotEmpty ? trimmed : 'http://localhost:5000';
  }
}
