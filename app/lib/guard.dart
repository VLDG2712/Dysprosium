import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Asked before every change on the Processes / Services / System settings tabs.
abstract class ChangeGuard {
  const ChangeGuard();

  /// True if the change may go ahead. [reason] is shown in the prompt ("End steam (4512)").
  Future<bool> allow(BuildContext context, String reason);
}

/// Fingerprint, face or the screen-lock PIN (whatever the phone has). On a phone without any
/// screen lock there is nothing to check, so it falls back to a plain confirmation.
class DeviceAuthGuard extends ChangeGuard {
  DeviceAuthGuard([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> allow(BuildContext context, String reason) async {
    try {
      if (!await _auth.isDeviceSupported()) {
        return context.mounted && await _confirm(context, reason);
      }
      return await _auth.authenticate(localizedReason: reason, persistAcrossBackgrounding: true);
    } on LocalAuthException catch (e) {
      switch (e.code) {
        case LocalAuthExceptionCode.noCredentialsSet:
          return context.mounted && await _confirm(context, reason);
        case LocalAuthExceptionCode.userCanceled ||
              LocalAuthExceptionCode.systemCanceled ||
              LocalAuthExceptionCode.timeout ||
              LocalAuthExceptionCode.userRequestedFallback:
          return false;
        default:
          if (context.mounted) {
            ScaffoldMessenger.maybeOf(context)
                ?.showSnackBar(SnackBar(content: Text('Couldn\'t check your fingerprint: ${e.description ?? e.code.name}')));
          }
          return false;
      }
    } on MissingPluginException {
      return context.mounted && await _confirm(context, reason);
    } on PlatformException {
      return context.mounted && await _confirm(context, reason);
    }
  }

  Future<bool> _confirm(BuildContext context, String reason) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(reason),
        content: const Text('This phone has no screen lock, so there is no fingerprint or PIN to ask for. '
            'Set one in Android settings to protect these actions.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Go ahead')),
        ],
      ),
    );
    return ok == true;
  }
}
