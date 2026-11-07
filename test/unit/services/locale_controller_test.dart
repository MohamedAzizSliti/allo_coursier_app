import 'package:allo_coursier_app/l10n/l10n.dart';
import 'package:allo_coursier_app/services/token_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('language choice survives a cold start from the same store', () async {
    final store = MemoryTokenStore();
    final first = LocaleController.forTest(store);
    await first.load();
    expect(first.hasChosenLanguage, isFalse);

    await first.setArabic(false);
    expect(first.hasChosenLanguage, isTrue);
    expect(first.isArabic, isFalse);

    final second = LocaleController.forTest(store);
    await second.load();
    expect(second.hasChosenLanguage, isTrue);
    expect(second.isArabic, isFalse);
  });

  test('a stored chosen flag still skips the welcome screen', () async {
    final store = MemoryTokenStore();
    await store.write('app_locale_chosen', '1');
    final locale = LocaleController.forTest(store);
    await locale.load();
    expect(locale.hasChosenLanguage, isTrue);
    expect(locale.isArabic, isTrue);
  });
}
