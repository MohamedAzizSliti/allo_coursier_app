import 'package:allo_coursier_app/models/user_model.dart';
import 'package:allo_coursier_app/services/onboarding_controller.dart';
import 'package:allo_coursier_app/services/token_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('overlay reapplies locally saved sender fields even if the API is blank', () async {
    final store = MemoryTokenStore();
    final onboarding = OnboardingController.forTest(store);
    const apiUser = UserModel(
      id: '8',
      email: '',
      name: 'verona',
      role: 'business_client',
    );
    const filled = UserModel(
      id: '8',
      email: '',
      name: 'verona',
      role: 'business_client',
      phone: '55555555',
      address: 'EZREZREZER',
      city: 'zaghouan',
      gouvernorat: 'Zaghouan',
      company: 'verona',
      cin: '111111111',
    );

    await onboarding.saveOverlay(filled);
    final merged = await onboarding.overlay(apiUser);

    expect(merged.name, 'verona');
    expect(merged.phone, '55555555');
    expect(merged.address, 'EZREZREZER');
    expect(merged.city, 'zaghouan');
    expect(merged.gouvernorat, 'Zaghouan');
    expect(merged.company, 'verona');
    expect(merged.cin, '111111111');
  });

  test('overlay restores a blank API user from the saved local card', () async {
    final store = MemoryTokenStore();
    final onboarding = OnboardingController.forTest(store);
    const filled = UserModel(
      id: '8',
      email: '',
      name: 'verona',
      role: 'business_client',
      phone: '55555555',
      city: 'zaghouan',
      gouvernorat: 'Zaghouan',
      company: 'verona',
    );
    await onboarding.saveOverlay(filled);

    const blank = UserModel(
      id: '8',
      email: '',
      name: '',
      role: 'business_client',
    );
    final merged = await onboarding.overlay(blank);
    expect(merged.name, 'verona');
    expect(merged.phone, '55555555');
    expect(merged.company, 'verona');
  });

  test('overlay still finds fields saved under an empty id', () async {
    final store = MemoryTokenStore();
    final onboarding = OnboardingController.forTest(store);
    const saved = UserModel(
      id: '',
      email: '',
      name: '',
      role: 'business_client',
      phone: '22123456',
      address: 'Rue 1',
      city: 'Zaghouan',
      gouvernorat: 'Zaghouan',
    );
    await onboarding.saveOverlay(saved);

    const later = UserModel(
      id: '8',
      email: '',
      name: 'verona',
      role: 'business_client',
    );
    final merged = await onboarding.overlay(later);
    expect(merged.phone, '22123456');
    expect(merged.city, 'Zaghouan');
  });
}
