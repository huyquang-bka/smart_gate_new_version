import 'package:smart_gate_new_version/core/configs/app_constants.dart';
import 'package:smart_gate_new_version/core/configs/app_theme.dart';
import 'package:smart_gate_new_version/core/services/auth_service.dart';
import 'package:smart_gate_new_version/core/services/mqtt_service.dart';
import 'package:smart_gate_new_version/features/seal/domain/models/container_harbor.dart';
import 'package:smart_gate_new_version/features/seal/widgets/seal_container_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:smart_gate_new_version/features/task/domain/models/task.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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

    String? result = await showDialog<String>(
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
          onSubmitted: (value) {
            Navigator.pop(context, value);
          },
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
              Navigator.pop(context, controller.text);
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        if (isFirstContainer) {
          _container1Controller.text = result;
        } else {
          _container2Controller.text = result;
        }
      });
    }
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
                widget.onTaskFinish();
                Navigator.pop(context); // Close success dialog
                Navigator.pop(context); // Back to task page
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
          actions: [
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _handleSend,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (containerHarbor != null) ...[
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  height: MediaQuery.of(context).size.height * 0.5,
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
                        onEditContainer: () =>
                            _editContainerCode(context, true),
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
                        onEditContainer: () =>
                            _editContainerCode(context, false),
                      ),
                    ],
                  ),
                ),
              ],
              _buildAdditionalInfo(),
            ],
          ),
        ),
      ),
    );
  }
}
