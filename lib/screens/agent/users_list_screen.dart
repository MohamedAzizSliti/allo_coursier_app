import 'package:flutter/material.dart';

import '../../domain/account_access.dart';
import '../../l10n/l10n.dart';
import '../../models/user_model.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_banner.dart';
import 'create_account_screen.dart';
import 'user_details_screen.dart';

class UsersListScreen extends StatefulWidget {
  final String role;

  const UsersListScreen({super.key, required this.role});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final UserApiService _userService = UserApiService();

  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _currentUserRole;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _userService.listUsers(role: widget.role),
          AlloApi.instance.getStoredRole(),
      ]);
      if (!mounted) return;

      final allUsers = results[0] as List<UserModel>;

      setState(() {
        _users = allUsers;
        _currentUserRole = results[1] as String?;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = context.s.cannotLoadUsers;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.s.listOf(context.s.roleTitle(widget.role))),
      ),
      floatingActionButton: _buildFloatingButton(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorBanner(message: _error!, onRetry: _fetchData)
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: _users.isEmpty
                  ? EmptyState(message: context.s.noneFound(context.s.roleTitle(widget.role)))
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) => _buildUserCard(_users[index]),
                    ),
            ),
    );
  }

  Widget? _buildFloatingButton() {
    if (!canCreateAccount(_currentUserRole, widget.role)) {
      return null;
    }

    return FloatingActionButton(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreateAccountScreen(role: widget.role),
          ),
        );
        _fetchData();
      },
      child: const Icon(Icons.account_circle_sharp),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserDetailsScreen(userId: user.id),
          ),
        );
      },
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.brown[300],
            child: const Icon(Icons.person, color: Colors.white),
          ),
          title: Text(user.name.isEmpty ? context.s.unknownName : user.name),
          subtitle: Text(user.email.isEmpty ? context.s.unknownEmail : user.email),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }
}
