import 'dart:convert';
import 'package:smart_gate_new_version/core/configs/api_route.dart';
import 'package:smart_gate_new_version/core/configs/app_theme.dart';
import 'package:smart_gate_new_version/core/services/auth_service.dart';
import 'package:smart_gate_new_version/core/services/custom_http_client.dart';
import 'package:smart_gate_new_version/core/services/mqtt_service.dart';
import 'package:smart_gate_new_version/features/seal/domain/models/check_point.dart';
import 'package:smart_gate_new_version/features/seal/domain/models/container_harbor.dart';
import 'package:smart_gate_new_version/features/seal/widgets/seal_container_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SealPage extends StatefulWidget {
  const SealPage({super.key});

  @override
  State<SealPage> createState() => _SealPageState();
}

class _SealPageState extends State<SealPage> {
  static const String _baseTopic = 'Event/Seal';
  // Container harbor
  ContainerHarbor? containerHarbor;
  CheckPoint? selectedCheckPoint;
  List<CheckPoint> checkPoints = [];
  bool isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCheckPoints();
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
        final List<dynamic> data = json.decode(response.body)["data"];
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
        final l10n = AppLocalizations.of(context)!;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.error,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: Text(l10n.errorLoadingCheckpoints(e.toString())),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _handleSend() async {
    final l10n = AppLocalizations.of(context)!;
    if (containerHarbor == null) return;

    if (selectedCheckPoint == null || selectedCheckPoint!.name == 'Unknown') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.warning,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Text(l10n.selectValidCheckpoint),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      return;
    }

    // Check container1 seal1 completion
    if (containerHarbor!.seal1.imagePath == null ||
        containerHarbor!.seal1.sealNumber1.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.warning,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Text(l10n.fillSealData),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.ok),
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
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text(l10n.sendingData),
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
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.success,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Text(l10n.dataSent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.ok),
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
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.error,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Text('${l10n.sendFailed}: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showCheckPointDialog() async {
    final l10n = AppLocalizations.of(context)!;
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
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.selectCheckpoint,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
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
                                        l10n.code(checkpoint.code),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (checkpoint.lanename != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          l10n.lane(checkpoint.lanename!),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
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
                      onPressed: () async {
                        if (selectedCheckPoint != null) {
                          Navigator.pop(context, selectedCheckPoint);
                        } else {
                          final auth = await AuthService.getAuth();
                          final unknownCheckpoint = CheckPoint(
                            id: 0,
                            compId: auth.compId,
                            name: l10n.unknown,
                            code: l10n.unknownCode,
                            lanename: null,
                          );
                          Navigator.pop(context, unknownCheckpoint);
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        l10n.cancel,
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

    if (selected != null) {
      await _onCheckPointSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.sealScanner,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
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
                    Text(
                      l10n.checkpointInfo,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
                        Expanded(
                          child: Text(
                            l10n.code(selectedCheckPoint!.code),
                            style: const TextStyle(fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                          Expanded(
                            child: Text(
                              l10n.lane(selectedCheckPoint!.lanename!),
                              style: const TextStyle(fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                label: Row(
                  children: [
                    const Icon(Icons.send),
                    const SizedBox(width: 8),
                    Text(l10n.send),
                  ],
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
