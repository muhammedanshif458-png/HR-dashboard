import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ly_hr_dashboard_flutter/widgets/custom_date_range_picker.dart';

Future<void> _loadCustomFonts() async {
  final fontLoader = FontLoader('Plus Jakarta Sans');
  for (final name in [
    'PlusJakartaSans-Regular.ttf',
    'PlusJakartaSans-Medium.ttf',
    'PlusJakartaSans-SemiBold.ttf',
    'PlusJakartaSans-Bold.ttf',
    'PlusJakartaSans-ExtraBold.ttf',
  ]) {
    final file = File('assets/fonts/$name');
    if (file.existsSync()) {
      final bytes = file.readAsBytesSync();
      fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
  }
  await fontLoader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadCustomFonts();
  });

  group('CustomDateRangePicker Widget & Visual Tests', () {
    testWidgets('renders all components matching reference design and captures preview',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final initialRange = DateTimeRange(
        start: DateTime(2026, 11, 10),
        end: DateTime(2026, 11, 19),
      );

      DateTimeRange? returnedRange;
      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'Plus Jakarta Sans',
            scaffoldBackgroundColor: const Color(0xFFF1F5F9),
          ),
          home: RepaintBoundary(
            key: repaintKey,
            child: Scaffold(
              backgroundColor: const Color(0xFFE2E8F0),
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      returnedRange = await showCustomDateRangePicker(
                        context: context,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2028),
                        initialDateRange: initialRange,
                      );
                    },
                    child: const Text('Open Date Picker'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap button to open date picker dialog
      await tester.tap(find.text('Open Date Picker'));
      await tester.pumpAndSettle();

      // 1. Verify Top Header controls
      expect(find.byKey(const ValueKey('custom_date_range_close_button')),
          findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byKey(const ValueKey('custom_date_range_save_button')),
          findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // 2. Verify Title, Range Header and Duration Badge
      expect(find.text('SELECT RANGE'), findsOneWidget);
      expect(find.text('Nov 10, 2026 – Nov 19, 2026'), findsOneWidget);
      expect(find.text('10 Days'), findsOneWidget);

      // 3. Verify Preset Filter Pills
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('November 2026'), findsWidgets); // Header & pill
      expect(find.text('December 2026'), findsWidgets); // Header & pill
      expect(find.text('Q4 2026'), findsOneWidget);

      // 4. Verify Months & Calendar Grid
      expect(find.byKey(const ValueKey('date_cell_2026_11_10')), findsOneWidget);
      expect(find.byKey(const ValueKey('date_cell_2026_11_19')), findsOneWidget);

      // 5. Verify Bottom Footer
      expect(find.textContaining('Selected:'), findsOneWidget);
      expect(find.text('Nov 10 – Nov 19, 2026'), findsOneWidget);
      expect(find.byKey(const ValueKey('custom_date_range_clear_button')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('custom_date_range_apply_button')),
          findsOneWidget);

      // 6. Capture preview snapshot of the dialog card
      await tester.runAsync(() async {
        final boundaryFinder =
            find.byKey(const ValueKey('custom_date_range_dialog_boundary'));
        final boundary = tester.renderObject(boundaryFinder) as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 2.0);
          final byteData =
              await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final file = File(
                'C:/Users/Admin/.gemini/antigravity/brain/31631a17-9a1a-41c5-93c8-8933458025ff/date_range_picker_preview.png');
            await file.writeAsBytes(byteData.buffer.asUint8List());
          }
        }
      });

      // 7. Test Apply Range returns current range
      await tester.tap(find.byKey(const ValueKey('custom_date_range_apply_button')));
      await tester.pumpAndSettle();

      expect(returnedRange, isNotNull);
      expect(returnedRange?.start, DateTime(2026, 11, 10));
      expect(returnedRange?.end, DateTime(2026, 11, 19));
    });

    testWidgets('interactively updates range when tapping dates and clear button',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      DateTimeRange? returnedRange;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Plus Jakarta Sans'),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () async {
                    returnedRange = await showCustomDateRangePicker(
                      context: context,
                      initialDateRange: DateTimeRange(
                        start: DateTime(2026, 11, 5),
                        end: DateTime(2026, 11, 8),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Nov 5, 2026 – Nov 8, 2026'), findsOneWidget);
      expect(find.text('4 Days'), findsOneWidget);

      // Tap Clear
      await tester.tap(find.byKey(const ValueKey('custom_date_range_clear_button')));
      await tester.pumpAndSettle();

      expect(find.text('Select Date Range'), findsOneWidget);
      expect(find.text('4 Days'), findsNothing);

      // Select new range: start = 12, end = 15
      await tester.tap(find.byKey(const ValueKey('date_cell_2026_11_12')));
      await tester.pumpAndSettle();

      expect(find.text('Nov 12, 2026 – Select End Date'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('date_cell_2026_11_15')));
      await tester.pumpAndSettle();

      expect(find.text('Nov 12, 2026 – Nov 15, 2026'), findsOneWidget);
      expect(find.text('4 Days'), findsOneWidget);

      // Tap Save button
      await tester.tap(find.byKey(const ValueKey('custom_date_range_save_button')));
      await tester.pumpAndSettle();

      expect(returnedRange, isNotNull);
      expect(returnedRange?.start, DateTime(2026, 11, 12));
      expect(returnedRange?.end, DateTime(2026, 11, 15));
    });
  });
}
