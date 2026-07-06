import 'package:flutter/material.dart';
import 'package:smart_gate_new_version/l10n/app_localizations.dart';

class OcrErrorDialog extends StatelessWidget {
  final String? errorMessage;

  const OcrErrorDialog({
    super.key,
    this.errorMessage,
  });

  static Future<void> show({
    required BuildContext context,
    String? errorMessage,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => OcrErrorDialog(
        errorMessage: errorMessage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 28,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.ocrApiError,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.ocrApiFailed,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getErrorMessage(l10n),
            style: const TextStyle(fontSize: 14),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.ok),
        ),
      ],
    );
  }

  String _getErrorMessage(AppLocalizations l10n) {
    if (errorMessage != null) {
      if (errorMessage!.contains('timeout') ||
          errorMessage!.contains('Timeout')) {
        return l10n.ocrApiTimeout;
      } else if (errorMessage!.contains('network') ||
          errorMessage!.contains('connection') ||
          errorMessage!.contains('Network')) {
        return l10n.ocrApiNetworkError;
      } else if (errorMessage!.contains('server') ||
          errorMessage!.contains('500') ||
          errorMessage!.contains('Server')) {
        return l10n.ocrApiServerError;
      }
    }
    return l10n.ocrApiErrorMessage;
  }
}
