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
