/// First-launch routing for [SessionGate].
enum AppEntry { language, onboarding, completeProfile, changePassword, shell }

/// Language welcome is only for a brand-new install. After a language is
/// chosen, onboarding is seen, or the user already has a session, that page
/// never comes back.
AppEntry resolveAppEntry({
  required bool hasChosenLanguage,
  required bool hasSeenOnboarding,
  required bool isSignedIn,
  required bool profileIncomplete,
  bool mustChangePassword = false,
}) {
  final firstLaunch =
      !hasChosenLanguage && !hasSeenOnboarding && !isSignedIn;
  if (firstLaunch) return AppEntry.language;
  if (!hasSeenOnboarding && !isSignedIn) return AppEntry.onboarding;
  if (isSignedIn && mustChangePassword) return AppEntry.changePassword;
  if (isSignedIn && profileIncomplete) return AppEntry.completeProfile;
  return AppEntry.shell;
}
