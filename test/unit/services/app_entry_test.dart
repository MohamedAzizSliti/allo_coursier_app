import 'package:allo_coursier_app/services/app_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('language screen is only for a brand-new install', () {
    expect(
      resolveAppEntry(
        hasChosenLanguage: false,
        hasSeenOnboarding: false,
        isSignedIn: false,
        profileIncomplete: false,
      ),
      AppEntry.language,
    );
  });

  test('after the first language pick, next launch opens onboarding', () {
    expect(
      resolveAppEntry(
        hasChosenLanguage: true,
        hasSeenOnboarding: false,
        isSignedIn: false,
        profileIncomplete: false,
      ),
      AppEntry.onboarding,
    );
  });

  test('signed-in users never see the language welcome again', () {
    expect(
      resolveAppEntry(
        hasChosenLanguage: false,
        hasSeenOnboarding: false,
        isSignedIn: true,
        profileIncomplete: false,
      ),
      AppEntry.shell,
    );
  });

  test('returning users who already saw onboarding skip language', () {
    expect(
      resolveAppEntry(
        hasChosenLanguage: false,
        hasSeenOnboarding: true,
        isSignedIn: false,
        profileIncomplete: false,
      ),
      AppEntry.shell,
    );
  });

  test('signed-in sender with missing fields opens the app', () {
    expect(
      resolveAppEntry(
        hasChosenLanguage: true,
        hasSeenOnboarding: true,
        isSignedIn: true,
        profileIncomplete: true,
      ),
      AppEntry.shell,
    );
  });

  test('temporary password must be changed before the rest of the app', () {
    expect(
      resolveAppEntry(
        hasChosenLanguage: true,
        hasSeenOnboarding: true,
        isSignedIn: true,
        profileIncomplete: true,
        mustChangePassword: true,
      ),
      AppEntry.changePassword,
    );
  });
}
