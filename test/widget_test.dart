import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/core/theme/app_theme.dart';

void main() {
  test('AppTheme validation test', () {
    final light = AppTheme.lightTheme;
    final dark = AppTheme.darkTheme;

    expect(light, isNotNull);
    expect(dark, isNotNull);
    expect(light.useMaterial3, isTrue);
    expect(dark.useMaterial3, isTrue);
  });
}
