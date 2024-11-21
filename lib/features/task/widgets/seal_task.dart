import 'package:smart_gate_new_version/core/configs/app_constants.dart';
import 'package:smart_gate_new_version/core/configs/app_theme.dart';
import 'package:smart_gate_new_version/core/services/auth_service.dart';
import 'package:smart_gate_new_version/core/services/mqtt_service.dart';
import 'package:smart_gate_new_version/features/seal/domain/models/check_point.dart';
import 'package:smart_gate_new_version/features/seal/domain/models/container_harbor.dart';
import 'package:smart_gate_new_version/features/seal/widgets/seal_container_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:smart_gate_new_version/features/task/domain/models/task.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:smart_gate_new_version/core/services/checkpoint_service.dart';

class SealTask extends StatefulWidget {
  const SealTask({
    super.key,
    required this.task,
    required this.onTaskFinish,
  });

  final Task task;
  final VoidCallback onTaskFinish;

  @override
  State<SealTask> createState() => _SealTaskState();
}

class _SealTaskState extends State<SealTask> {
  static const String _baseTopic = 'Event/Seal';
  ContainerHarbor? containerHarbor;
  bool isLoading = true;
  late TextEditingController _container1Controller;
  late TextEditingController _container2Controller;
  late TextEditingController _descriptionController;
  late PageController _pageController;
  final ImagePicker _picker = ImagePicker();
  List<XFile> additionalImages = [];
  List<CheckPoint> _checkpoints = [];
  final FocusNode _container1FocusNode = FocusNode();
  final FocusNode _container2FocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _container1Controller =
        TextEditingController(text: widget.task.containerCode1);
    _container2Controller =
        TextEditingController(text: widget.task.containerCode2 ?? "?");
    _descriptionController = TextEditingController();
    _pageController = PageController();
    _initializeContainerHarbor();
    _loadCheckpoints();
  }

  @override
  void dispose() {
    _container1Controller.dispose();
    _container2Controller.dispose();
    _descriptionController.dispose();
    _pageController.dispose();
    _container1FocusNode.dispose();
    _container2FocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _captureAdditionalImage() async {
    if (additionalImages.length >= AppConstants.maxAdditionalImages) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        additionalImages.add(image);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      additionalImages.removeAt(index);
    });
  }

  void _showImageDialog(XFile image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Image.file(
                  File(image.path),
                  fit: BoxFit.contain,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeContainerHarbor() async {
    final auth = await AuthService.getAuth();
    setState(() {
      containerHarbor = ContainerHarbor(
        checkPointId: widget.task.checkPointId.toString(),
        userID: auth.userId.toString(),
        fullName: auth.fullName,
      );
      isLoading = false;
    });
  }

  Future<void> _editContainerCode(
      BuildContext context, bool isFirstContainer) async {
    final l10n = AppLocalizations.of(context)!;
    final controller =
        isFirstContainer ? _container1Controller : _container2Controller;
    final focusNode =
        isFirstContainer ? _container1FocusNode : _container2FocusNode;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(isFirstContainer ? l10n.editContainer1 : l10n.editContainer2),
        content: TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: l10n.containerCode,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              focusNode.unfocus();
              Navigator.pop(context);
            },
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              focusNode.unfocus();
              setState(() {});
              Navigator.pop(context);
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSend() async {
    final l10n = AppLocalizations.of(context)!;
    if (containerHarbor == null) return;

    _container1FocusNode.unfocus();
    _container2FocusNode.unfocus();
    _descriptionFocusNode.unfocus();

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
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(l10n.sendingData),
            ],
          ),
        ),
      );

      final jsonData = containerHarbor!.toJson();
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
          checkPointId: widget.task.checkPointId.toString(),
          userID: auth.userId.toString(),
          fullName: auth.fullName,
        );
        additionalImages.clear();
        _descriptionController.clear();
      });

      // Show success dialog
      await showDialog(
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
              onPressed: () {
                Navigator.pop(context);
                widget.onTaskFinish();
              },
              style: AppTheme.actionButtonStyle,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.ok,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
          content: Text(l10n.sendFailed(l10n.connectError)),
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

  Future<void> _loadCheckpoints() async {
    final checkpoints = await CheckpointService.getAllCheckpoints();
    setState(() {
      _checkpoints = checkpoints;
    });
  }

  String _getCheckpointDisplay(String checkpointId) {
    final l10n = AppLocalizations.of(context)!;
    final checkpoint = _checkpoints.firstWhere(
      (cp) => cp.id.toString() == checkpointId,
      orElse: () => CheckPoint(
        id: -1,
        name: l10n.unknownCheckpoint,
        code: '',
        compId: -1,
      ),
    );

    return checkpoint.lanename != null && checkpoint.lanename!.isNotEmpty
        ? l10n.checkpointWithLane(checkpoint.name, checkpoint.lanename!)
        : checkpoint.name;
  }

  Widget _buildTaskInfo() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
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
          Row(
            children: [
              const Icon(
                Icons.local_shipping,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.containerInformation,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.inventory_2, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.container1Code(_container1Controller.text),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _editContainerCode(context, true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.inventory_2, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.container2Code(_container2Controller.text),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _editContainerCode(context, false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 20),
              const SizedBox(width: 8),
              Text(
                '${l10n.checkpointLabel}: ',
                style: const TextStyle(fontSize: 14),
              ),
              Expanded(
                child: Text(
                  _getCheckpointDisplay(widget.task.checkPointId.toString()),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.time(DateFormat('HH:mm:ss dd-MM-yyyy')
                    .format(widget.task.timeInOut.toLocal())),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.additionalInformation,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                l10n.maxImages(
                  additionalImages.length.toString(),
                  AppConstants.maxAdditionalImages.toString(),
                ),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (additionalImages.length < AppConstants.maxAdditionalImages)
                  Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add_photo_alternate, size: 32),
                      onPressed: _captureAdditionalImage,
                    ),
                  ),
                ...additionalImages.asMap().entries.map((entry) {
                  final index = entry.key;
                  final image = entry.value;
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _showImageDialog(image),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(image.path),
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () => _removeImage(index),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            focusNode: _descriptionFocusNode,
            decoration: InputDecoration(
              labelText: l10n.description,
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: () {
        _container1FocusNode.unfocus();
        _container2FocusNode.unfocus();
        _descriptionFocusNode.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            l10n.sealScanner,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTaskInfo(),
              if (containerHarbor != null) ...[
                SizedBox(
                  height: 500,
                  child: PageView(
                    controller: _pageController,
                    children: [
                      SealContainerPicker(
                        key: const ValueKey('container1'),
                        index: 1,
                        containerCode: _container1Controller.text,
                        seal: containerHarbor!.seal1,
                        onSealChanged: (updatedSeal) {
                          setState(() {
                            containerHarbor = containerHarbor!.copyWith(
                              seal1: updatedSeal,
                            );
                          });
                        },
                      ),
                      SealContainerPicker(
                        key: const ValueKey('container2'),
                        index: 2,
                        containerCode: _container2Controller.text,
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
                  ),
                ),
              ],
              _buildAdditionalInfo(),
              const SizedBox(height: 100),
            ],
          ),
        ),
        floatingActionButton: Container(
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
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}
