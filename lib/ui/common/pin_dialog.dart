import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_wholesale_erp/core/constants/app_colors.dart';
import 'package:mobile_wholesale_erp/core/services/security_service.dart';
import 'package:mobile_wholesale_erp/providers/app_state.dart';

class PinDialog extends StatefulWidget {
  final String title;
  final String message;

  const PinDialog({
    super.key,
    required this.title,
    required this.message,
  });

  static Future<bool> verify(BuildContext context, {required String title, required String message}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PinDialog(title: title, message: message),
    );
    return result ?? false;
  }

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final TextEditingController _pinController = TextEditingController();
  String? _errorText;
  int _attempts = 0;

  void _submit() {
    final appState = context.read<AppState>();
    final storedHash = appState.settings.ownerPinHash;
    final storedSalt = appState.settings.ownerPinSalt;

    final entered = _pinController.text.trim();
    if (entered.isEmpty) {
      setState(() => _errorText = 'Enter 4-digit PIN');
      return;
    }

    // Default PIN for demo is "1234" if not set
    bool isValid;
    if (appState.isDemoMode && storedHash.isEmpty) {
      isValid = entered == '1234';
    } else {
      isValid = SecurityService.instance.verifyPin(entered, storedHash, storedSalt);
    }

    if (isValid) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _attempts++;
        _errorText = 'Incorrect PIN! (${3 - _attempts} attempts left)';
      });
      if (_attempts >= 3) {
        Navigator.of(context).pop(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(
        children: [
          const Icon(Icons.lock_outline, color: AppColors.highlightAmberDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Enter Owner PIN (Demo: 1234)',
              errorText: _errorText,
              counterText: '',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Authorize'),
        ),
      ],
    );
  }
}

