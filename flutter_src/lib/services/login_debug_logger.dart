import 'dart:convert';
import 'package:flutter/foundation.dart';

class LoginDebugEntry {
  final DateTime timestamp;
  final String message;
  final String level; // 'info', 'request', 'response', 'success', 'warning', 'error', 'json', 'token'
  final String? details;

  LoginDebugEntry({
    required this.timestamp,
    required this.message,
    this.level = 'info',
    this.details,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}

class LoginDebugLogger with ChangeNotifier {
  static final LoginDebugLogger instance = LoginDebugLogger._internal();
  factory LoginDebugLogger() => instance;
  LoginDebugLogger._internal();

  final List<LoginDebugEntry> _entries = [];
  List<LoginDebugEntry> get entries => List.unmodifiable(_entries);

  String? rawResponseJson;
  String? extractedToken;
  String? tokenJsonPath;
  bool isTokenStored = false;
  bool isTokenMissing = false;
  int? lastStatusCode;
  bool? lastLoginSuccess;

  void log(String message, {String level = 'info', String? details}) {
    _entries.add(LoginDebugEntry(
      timestamp: DateTime.now(),
      message: message,
      level: level,
      details: details,
    ));
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    rawResponseJson = null;
    extractedToken = null;
    tokenJsonPath = null;
    isTokenStored = false;
    isTokenMissing = false;
    lastStatusCode = null;
    lastLoginSuccess = null;
    notifyListeners();
  }

  String _maskEmail(String email) {
    final trimmed = email.trim();
    if (!trimmed.contains('@')) return trimmed;
    final parts = trimmed.split('@');
    final user = parts[0];
    final domain = parts[1];
    if (user.length <= 2) {
      return '$user***@$domain';
    }
    return '${user.substring(0, 2)}***@$domain';
  }

  void logLoginClick(String email) {
    final masked = _maskEmail(email);
    log('Login button clicked for account: $masked', level: 'info');
  }

  void logRequestStart({required String url, required String method}) {
    log('Network request dispatched: $method $url', level: 'request');
    log('Request headers: Content-Type: application/json, Accept: application/json',
        level: 'info');
  }

  void logResponseReceived({
    required int statusCode,
    required String rawBody,
    dynamic decodedBody,
  }) {
    lastStatusCode = statusCode;
    log('HTTP response received: Status $statusCode',
        level: statusCode >= 200 && statusCode < 300 ? 'response' : 'warning');

    String formattedJson = '';
    if (decodedBody is Map || decodedBody is List) {
      try {
        const encoder = JsonEncoder.withIndent('  ');
        // Ensure sensitive fields (like password) are never present in logs
        final sanitized = _sanitizeJsonForLogging(decodedBody);
        formattedJson = encoder.convert(sanitized);
      } catch (_) {
        formattedJson = rawBody;
      }
    } else {
      formattedJson = rawBody;
    }

    rawResponseJson = formattedJson;
    log('Response JSON Body:\n$formattedJson',
        level: 'json', details: formattedJson);
  }

  void logTokenAnalysis({
    required dynamic decoded,
    required String? token,
    required bool storedSuccessfully,
  }) {
    if (decoded is! Map<String, dynamic>) {
      isTokenMissing = true;
      tokenJsonPath = 'N/A';
      log('[ERROR] Cannot inspect token: decoded response is not a JSON object.',
          level: 'error');
      return;
    }

    final data = decoded['data'];
    String? foundPath;

    if (data is Map<String, dynamic>) {
      if (data['token'] != null && data['token'].toString().trim().isNotEmpty) {
        foundPath = 'data.token';
      } else if (data['accessToken'] != null &&
          data['accessToken'].toString().trim().isNotEmpty) {
        foundPath = 'data.accessToken';
      }
    }

    if (foundPath == null) {
      if (decoded['token'] != null &&
          decoded['token'].toString().trim().isNotEmpty) {
        foundPath = 'token';
      } else if (decoded['accessToken'] != null &&
          decoded['accessToken'].toString().trim().isNotEmpty) {
        foundPath = 'accessToken';
      }
    }

    tokenJsonPath = foundPath ?? 'None (missing)';

    if (token != null && token.isNotEmpty) {
      isTokenMissing = false;
      isTokenStored = storedSuccessfully;
      // In production/release builds, never keep the raw token in debug logger
      extractedToken = kDebugMode ? token : '[REDACTED in production build]';

      log('Token verification: Token exists in response at "$tokenJsonPath".',
          level: 'success');
      log('Token storage: Extracted and successfully stored in ApiService: $storedSuccessfully',
          level: storedSuccessfully ? 'success' : 'error');

      if (kDebugMode) {
        final previewLength = token.length > 24 ? 24 : token.length;
        log('Token preview: ${token.substring(0, previewLength)}...',
            level: 'token');
      } else {
        log('Token visibility disabled in release mode for security.',
            level: 'warning');
      }
    } else {
      isTokenMissing = true;
      isTokenStored = false;
      extractedToken = null;
      log('[DIAGNOSTIC ERROR] Authentication token is MISSING from response envelope. Expected field: "data.token" or "data.accessToken".',
          level: 'error');
    }
    notifyListeners();
  }

  void logException({required String message, dynamic exception}) {
    log('API / Parsing Exception: $message',
        level: 'error', details: exception?.toString());
  }

  dynamic _sanitizeJsonForLogging(dynamic input) {
    if (input is Map) {
      final sanitized = <String, dynamic>{};
      for (final entry in input.entries) {
        final key = entry.key.toString();
        final lower = key.toLowerCase();
        if (lower.contains('password') ||
            lower.contains('secret') ||
            lower == 'refreshtoken') {
          sanitized[key] = '[REDACTED]';
        } else if (entry.value is Map || entry.value is List) {
          sanitized[key] = _sanitizeJsonForLogging(entry.value);
        } else {
          sanitized[key] = entry.value;
        }
      }
      return sanitized;
    } else if (input is List) {
      return input.map(_sanitizeJsonForLogging).toList();
    }
    return input;
  }
}
