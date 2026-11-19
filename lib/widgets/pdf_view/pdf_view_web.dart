// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

final Set<String> _registeredPdfViews = {};

Widget buildPdfPlatformView({
  required String blobUrl,
  required String title,
}) {
  final viewType = 'pdf-frame-${blobUrl.hashCode}';

  if (!_registeredPdfViews.contains(viewType)) {
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = '$blobUrl#toolbar=1'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        return iframe;
      },
    );
    _registeredPdfViews.add(viewType);
  }

  return HtmlElementView(
    key: ValueKey(viewType),
    viewType: viewType,
  );
}
