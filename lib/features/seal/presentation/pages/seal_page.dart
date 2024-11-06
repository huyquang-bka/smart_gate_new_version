import 'dart:convert';
import 'package:clean_store_app/core/configs/api_route.dart';
import 'package:clean_store_app/core/configs/app_theme.dart';
import 'package:clean_store_app/core/routes/routes.dart';
import 'package:clean_store_app/core/services/auth_service.dart';
import 'package:clean_store_app/core/services/custom_http_client.dart';
import 'package:clean_store_app/core/services/mqtt_service.dart';
import 'package:clean_store_app/features/seal/domain/models/check_point.dart';
import 'package:clean_store_app/features/seal/domain/models/container_harbor.dart';
import 'package:clean_store_app/features/seal/widgets/seal_container_picker.dart';
import 'package:flutter/material.dart';

class SealPage extends StatefulWidget {
  const SealPage({super.key});

  @override
  State<SealPage> createState() => _SealPageState();
}

class _SealPageState extends State<SealPage> {
  // Mqtt service
  late MqttService mqttService;
  static const String _baseTopic = 'Event/Seal';
  static const String _broker = '27.72.98.49';
  static const int _port = 58883;
  static const String _username = 'admin';
  static const String _password = 'admin';
  final String _clientId = DateTime.now().millisecondsSinceEpoch.toString();

  // Container harbor
  ContainerHarbor? containerHarbor;
  CheckPoint? selectedCheckPoint;
  List<CheckPoint> checkPoints = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCheckPoints();
    _initializeMqtt();
  }

  @override
  void dispose() {
    mqttService.disconnect();
    super.dispose();
  }

  Future<void> _initializeMqtt() async {
    try {
      mqttService = MqttService(
        broker: _broker,
        port: _port,
        clientId: _clientId,
        username: _username,
        password: _password,
        topic: _baseTopic,
      );
      await mqttService.connect();
      print('MQTT Connected');
    } catch (e) {
      print('Error connecting to MQTT: $e');
    }
  }

  Future<void> _onCheckPointSelected(CheckPoint checkpoint) async {
    final auth = await AuthService.getAuth();
    setState(() {
      selectedCheckPoint = checkpoint;
      containerHarbor = ContainerHarbor(
        checkPointId: checkpoint.id.toString(),
        userID: auth.userId.toString(),
        fullName: auth.fullName,
      );
    });
  }

  Future<void> _loadCheckPoints() async {
    try {
      setState(() => isLoading = true);

      final auth = await AuthService.getAuth();

      // Fetch checkpoints
      final response = await customHttpClient.get(Url.getCheckPoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)["data"];
        final allCheckPoints = data
            .map((json) => CheckPoint.fromJson(json))
            .where((checkpoint) => checkpoint.compId == auth.compId)
            .toList();

        setState(() {
          checkPoints = allCheckPoints;
          isLoading = false;
        });

        if (mounted && checkPoints.isNotEmpty) {
          _showCheckPointDialog();
        }
      } else {
        throw Exception('Failed to load checkpoints');
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Error loading checkpoints: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _handleSend() async {
    if (containerHarbor == null) return;

    // Check container1 seal1 completion
    if (containerHarbor!.seal1.imagePath == null ||
        containerHarbor!.seal1.sealNumber1.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Incomplete Data'),
            ],
          ),
          content: const Text('Please fill in at least Seal 1 for Container 1'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Sending data...'),
            ],
          ),
        ),
      );

      final jsonData = containerHarbor!.toJson();
      print("Ready to send data");
      // Send data via MQTT
      await mqttService.sendMessage(
        _baseTopic,
        jsonData,
      );
      if (!mounted) return;
      Navigator.pop(context); // Remove loading dialog

      // Clear data
      final auth = await AuthService.getAuth();
      setState(() {
        containerHarbor = ContainerHarbor(
          checkPointId: selectedCheckPoint!.id.toString(),
          userID: auth.userId.toString(),
          fullName: auth.fullName,
        );
      });

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Success'),
            ],
          ),
          content: const Text('Data sent successfully'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Remove loading dialog

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text('Failed to send data: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showCheckPointDialog() async {
    final selected = await showDialog<CheckPoint?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Select Checkpoint',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: checkPoints.length,
                  itemBuilder: (context, index) {
                    final checkpoint = checkPoints[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: InkWell(
                          onTap: () => Navigator.pop(context, checkpoint),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: AppTheme.primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        checkpoint.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: 28),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Code: ${checkpoint.code}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (checkpoint.lanename != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Lane: ${checkpoint.lanename}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, null);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) {
      // User cancelled, navigate back to dashboard
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(Routes.main, (route) => false);
      }
    } else {
      await _onCheckPointSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seal Scanner'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () => _showCheckPointDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedCheckPoint != null) ...[
              // Checkpoint info card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Checkpoint Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            selectedCheckPoint!.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.code,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Code: ${selectedCheckPoint!.code}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    if (selectedCheckPoint!.lanename != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.straighten,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Lane: ${selectedCheckPoint!.lanename}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (containerHarbor != null) ...[
                SealContainerPicker(
                  index: 1,
                  seal: containerHarbor!.seal1,
                  onSealChanged: (updatedSeal) {
                    setState(() {
                      containerHarbor = containerHarbor!.copyWith(
                        seal1: updatedSeal,
                      );
                    });
                  },
                ),
                const SizedBox(height: 16),
                SealContainerPicker(
                  index: 2,
                  seal: containerHarbor!.seal2,
                  onSealChanged: (updatedSeal) {
                    setState(() {
                      containerHarbor = containerHarbor!.copyWith(
                        seal2: updatedSeal,
                      );
                    });
                  },
                ),
              ],
              const SizedBox(height: 100),
            ],
          ],
        ),
      ),
      floatingActionButton: selectedCheckPoint != null
          ? Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: FloatingActionButton.extended(
                onPressed: _handleSend,
                backgroundColor: AppTheme.primaryColor,
                label: const Row(
                  children: [
                    Icon(Icons.send),
                    SizedBox(width: 8),
                    Text('Send'),
                  ],
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
