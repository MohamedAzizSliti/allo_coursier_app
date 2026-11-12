import 'package:allo_coursier_app/domain/account_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canBanOrDeleteAccount', () {
    test('admin may manage agents, senders and drivers', () {
      expect(
        canBanOrDeleteAccount(
          actorRole: 'admin',
          targetRole: 'agent',
          actorId: '1',
          targetId: '2',
        ),
        isTrue,
      );
      expect(
        canBanOrDeleteAccount(
          actorRole: 'admin',
          targetRole: 'business_client',
          actorId: '1',
          targetId: '3',
        ),
        isTrue,
      );
      expect(
        canBanOrDeleteAccount(
          actorRole: 'admin',
          targetRole: 'delivery_person',
          actorId: '1',
          targetId: '4',
        ),
        isTrue,
      );
    });

    test('agent may manage senders and drivers only', () {
      expect(
        canBanOrDeleteAccount(
          actorRole: 'agent',
          targetRole: 'business_client',
          actorId: '2',
          targetId: '8',
        ),
        isTrue,
      );
      expect(
        canBanOrDeleteAccount(
          actorRole: 'agent',
          targetRole: 'delivery_person',
          actorId: '2',
          targetId: '5',
        ),
        isTrue,
      );
      expect(
        canBanOrDeleteAccount(
          actorRole: 'agent',
          targetRole: 'agent',
          actorId: '2',
          targetId: '3',
        ),
        isFalse,
      );
    });

    test('never self or admin targets', () {
      expect(
        canBanOrDeleteAccount(
          actorRole: 'admin',
          targetRole: 'admin',
          actorId: '1',
          targetId: '9',
        ),
        isFalse,
      );
      expect(
        canBanOrDeleteAccount(
          actorRole: 'admin',
          targetRole: 'agent',
          actorId: '1',
          targetId: '1',
        ),
        isFalse,
      );
    });
  });
}
