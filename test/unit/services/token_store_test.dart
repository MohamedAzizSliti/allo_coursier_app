import 'package:allo_coursier_app/services/token_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThrowingStore implements TokenStore {
  @override
  Future<void> write(String key, String value) async {
    throw StateError('keystore');
  }

  @override
  Future<String?> read(String key) async {
    throw StateError('keystore');
  }

  @override
  Future<void> delete(String key) async {
    throw StateError('keystore');
  }

  @override
  Future<void> deleteAll() async {
    throw StateError('keystore');
  }
}

void main() {
  test('FallbackTokenStore keeps values when primary store fails', () async {
    final store = FallbackTokenStore(_ThrowingStore());
    await store.write('access_token', 'abc');
    expect(await store.read('access_token'), 'abc');
    await store.delete('access_token');
    expect(await store.read('access_token'), isNull);

    await store.write('access_token', 'abc');
    await store.write('app_locale', 'ar');
    await store.delete('access_token');
    expect(await store.read('app_locale'), 'ar');

    await store.deleteAll();
    expect(await store.read('access_token'), isNull);
  });
}
