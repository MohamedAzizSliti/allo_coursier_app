/// Who may open the create-account screen for [role].
///
/// Admin creates drivers, agents, and expéditeurs. An agent creates expéditeurs
/// and other agents. Nobody creates an admin from this screen.
bool canCreateAccount(String? actorRole, String role) {
  if (role == 'delivery_person') return actorRole == 'admin';
  if (role == 'agent' || role == 'business_client') {
    return actorRole == 'admin' || actorRole == 'agent';
  }
  return false;
}

/// Admin may ban/delete agents, expéditeurs and drivers.
/// Agent may ban/delete expéditeurs and drivers only.
/// Never self, admin, or agent→agent.
bool canBanOrDeleteAccount({
  required String? actorRole,
  required String targetRole,
  required String actorId,
  required String targetId,
}) {
  if (actorId.isEmpty || targetId.isEmpty || actorId == targetId) return false;
  if (targetRole == 'admin') return false;
  if (actorRole == 'admin') {
    return targetRole == 'agent' ||
        targetRole == 'business_client' ||
        targetRole == 'delivery_person';
  }
  if (actorRole == 'agent') {
    return targetRole == 'business_client' || targetRole == 'delivery_person';
  }
  return false;
}
