import 'package:allo_coursier_app/theme/app_theme.dart';
import 'package:allo_coursier_app/widgets/password_update_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('password fields reject a mismatched confirmation', (tester) async {
    final current = TextEditingController(text: 'oldpass');
    final next = TextEditingController(text: 'newpass');
    final confirm = TextEditingController(text: 'other');
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Form(
            key: formKey,
            child: PasswordUpdateFields(
              currentController: current,
              newController: next,
              confirmController: confirm,
              obscureCurrent: true,
              obscureNew: true,
              obscureConfirm: true,
              onToggleCurrent: () {},
              onToggleNew: () {},
              onToggleConfirm: () {},
            ),
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('كلمتا المرور غير متطابقتين'), findsOneWidget);
  });

  testWidgets('optional password fields can stay empty', (tester) async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Form(
            key: formKey,
            child: PasswordUpdateFields(
              currentController: current,
              newController: next,
              confirmController: confirm,
              obscureCurrent: true,
              obscureNew: true,
              obscureConfirm: true,
              onToggleCurrent: () {},
              onToggleNew: () {},
              onToggleConfirm: () {},
              optional: true,
            ),
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isTrue);
  });
}
