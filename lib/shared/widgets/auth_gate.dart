import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../features/auth/screens/login_dialog.dart';
import '../../providers/auth_provider.dart';

/// Runs [action] only if the user is signed in. Otherwise pops the login
/// dialog and runs [action] only after a successful sign-in.
///
/// Use this around any tap handler that should be guarded — wishlist toggles,
/// add-to-cart, etc. — so guests get a consistent prompt instead of silent
/// fall-throughs into local-only state.
Future<void> requireAuth(
  BuildContext context, {
  required Future<void> Function() action,
  String? message,
}) async {
  final auth = context.read<AuthProvider>();
  if (auth.isLoggedIn) {
    await action();
    return;
  }

  final loggedIn = message != null
      ? await LoginDialog.showWithMessage(context, message)
      : await LoginDialog.show(context);
  if (!loggedIn) return;
  if (!context.mounted) return;
  // Re-check; the dialog returns true only on successful login but be safe.
  if (!context.read<AuthProvider>().isLoggedIn) return;
  await action();
}
