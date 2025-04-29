import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:smart_gate_new_version/core/configs/app_constants.dart';
import 'package:smart_gate_new_version/core/services/mqtt_service.dart';

class MqttConnectionStatus extends StatelessWidget {
  const MqttConnectionStatus({super.key});

  void _showConnectionDetails(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mqttService = context.read<MqttService>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('MQTT Connection Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Broker', AppConstants.mqttBroker),
            const SizedBox(height: 8),
            _buildDetailRow('Port', AppConstants.mqttPort.toString()),
            const SizedBox(height: 8),
            _buildDetailRow('Status',
                mqttService.isConnected ? 'Connected' : 'Disconnected'),
            const SizedBox(height: 8),
            _buildDetailRow('Client ID', mqttService.client.clientIdentifier),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mqttService = context.watch<MqttService>();

    return StreamBuilder<bool>(
      stream: mqttService.connectionStream,
      initialData: mqttService.isConnected,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? false;

        return GestureDetector(
          onTap: () => _showConnectionDetails(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isConnected
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isConnected ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isConnected ? Icons.cloud_done : Icons.cloud_off,
                  size: 16,
                  color: isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: isConnected ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
