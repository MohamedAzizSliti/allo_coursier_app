import '../models/user_model.dart';
import 'api_client.dart';

class UserApiService {
  UserApiService([AlloApi? api]) : _api = api ?? AlloApi.instance;

  final AlloApi _api;

  Future<List<UserModel>> listUsers({String? role}) async {
    final query = <String, dynamic>{};
    if (role != null && role.isNotEmpty) query['role'] = role;
    final list = await _api.getList('/users', query.isEmpty ? null : query);
    return list.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UserModel> getUser(String id) async {
    final data = await _api.get('/users/$id');
    return UserModel.fromJson(data);
  }

  Future<UserModel> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? address,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };
    if (phone != null) body['phone'] = phone;
    if (address != null) body['address'] = address;

    final data = await _api.post('/users', body);
    return UserModel.fromJson(data);
  }

  Future<void> deleteUser(String id) async {
    await _api.delete('/users/$id');
  }

  Future<UserModel> updateProfile(UserModel user) async {
    final data = await _api.patch('/users/${user.id}', user.toProfileBody());
    return UserModel.fromJson(data).mergedWith(user);
  }
}
