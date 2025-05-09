import 'package:smart_gate_new_version/core/configs/api_route.dart';
import 'package:smart_gate_new_version/core/configs/app_constants.dart';
import 'package:smart_gate_new_version/core/configs/app_theme.dart';
import 'package:smart_gate_new_version/core/services/auth_service.dart';
import 'package:smart_gate_new_version/core/services/custom_http_client.dart';
import 'package:smart_gate_new_version/core/services/mqtt_service.dart';
import 'package:smart_gate_new_version/features/seal/domain/models/container_harbor.dart';
import 'package:smart_gate_new_version/features/seal/widgets/seal_container_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:smart_gate_new_version/features/task/domain/models/task.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

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
  static const int _maxUploadRetries = 3;

  ContainerHarbor? containerHarbor;
  bool isLoading = true;
  final List<XFile> additionalImages = [];
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _container1Controller;
  late final TextEditingController _container2Controller;
  late final PageController _pageController;

  final FocusNode _container1FocusNode = FocusNode();
  final FocusNode _container2FocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    print("-----------task: ${widget.task.toJson()}");
    print("-----------containerCode1: ${widget.task.containerCode1}");
    print("-----------containerCode2: ${widget.task.containerCode2}");
    _initControllers();
    _initializeContainerHarbor();
  }

  void _initControllers() {
    _container1Controller =
        TextEditingController(text: widget.task.containerCode1);
    _container2Controller =
        TextEditingController(text: widget.task.containerCode2 ?? "?");
    _pageController = PageController();
  }

  @override
  void dispose() {
    _container1Controller.dispose();
    _container2Controller.dispose();
    _pageController.dispose();
    _container1FocusNode.dispose();
    _container2FocusNode.dispose();
    super.dispose();
  }

  Future<void> _captureAdditionalImage() async {
    if (additionalImages.length >= AppConstants.maxAdditionalImages) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() => additionalImages.add(image));
    }
  }

  void _removeImage(int index) {
    setState(() => additionalImages.removeAt(index));
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

    final result = await showDialog<String>(
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
          onSubmitted: (value) => Navigator.pop(context, value),
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

  Future<String?> _uploadImage(String imagePath) async {
    int retryCount = 0;
    while (retryCount < _maxUploadRetries) {
      try {
        final uri = Uri.parse(Url.saveFile);
        final request = await customHttpClient.multipartRequest('POST', uri);

        request.files.add(
          await http.MultipartFile.fromPath('file', imagePath),
        );

        final response = await customHttpClient.sendMultipartRequest(request);
        if (response.statusCode == 200) {
          final responseBody = await response.stream.bytesToString();
          return responseBody.replaceAll('"', '');
        }
        retryCount++;
        if (retryCount == _maxUploadRetries) {
          throw Exception(
              'Failed to upload image after $_maxUploadRetries attempts: ${response.statusCode}');
        }
      } catch (e) {
        retryCount++;
        if (retryCount == _maxUploadRetries) {
          throw Exception(
              'Error uploading image after $_maxUploadRetries attempts: $e');
        }
      }
    }
    return null;
  }

  Future<bool> _showSealWarningDialog(List<String> warnings) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.error,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.warningSealIncomplete,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...warnings.map((warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          warning,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
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

    return false;
  }

  Future<void> _handleSend() async {
    final l10n = AppLocalizations.of(context)!;
    if (containerHarbor == null) return;

    _container1FocusNode.unfocus();
    _container2FocusNode.unfocus();

    // Check for missing information
    List<String> warnings = [];

    // Check seal 1 (only seal 1 exists)
    if (widget.task.containerCode1 != null &&
        widget.task.containerCode1!.isNotEmpty) {
      if (containerHarbor!.seal1.sealNumber1.isEmpty) {
        warnings.add(l10n.warningSealMissingText1);
      }
      if (containerHarbor!.seal1.imagePath == null) {
        warnings.add(l10n.warningSealMissingImage1);
      }
    }

    // Check seal 2 (only if container 2 exists)
    if (widget.task.containerCode2 != null) {
      if (containerHarbor!.seal2.sealNumber1.isEmpty) {
        warnings.add(l10n.warningSealMissingText2);
      }
      if (containerHarbor!.seal2.imagePath == null) {
        warnings.add(l10n.warningSealMissingImage2);
      }
    }

    // If there are warnings, show dialog
    if (warnings.isNotEmpty) {
      final shouldContinue = await _showSealWarningDialog(warnings);
      if (!shouldContinue) {
        return;
      }
    }

    print("-----------Container Harbor: ${containerHarbor!}");
    _showLoadingDialog(l10n);

    // Upload seal images
    try {
      await _uploadSealImages();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorDialog(l10n, e.toString());
      return;
    }

    // Upload additional images
    try {
      await _uploadAdditionalImages();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorDialog(l10n, e.toString());
      return;
    }

    // Send data via MQTT
    try {
      _updateContainerHarborData();
      await _sendDataViaMqtt();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showErrorDialog(l10n, e.toString());
      return;
    }

    // Show success dialog
    if (!mounted) return;
    Navigator.pop(context); // Remove loading dialog
    await _showSuccessDialog(l10n);
  }

  // bool _validateSealData(AppLocalizations l10n) {
  //   if (containerHarbor!.seal1.imagePath == null ||
  //       containerHarbor!.seal1.sealNumber1.isEmpty) {
  //     _showWarningDialog(l10n);
  //     return false;
  //   }
  //   return true;
  // }

  void _showLoadingDialog(AppLocalizations l10n) {
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
  }

  Future<void> _uploadSealImages() async {
    if (containerHarbor!.seal1.imagePath != null) {
      final seal1ImagePath =
          await _uploadImage(containerHarbor!.seal1.imagePath!);
      if (seal1ImagePath != null) {
        setState(() {
          containerHarbor!.seal1.savedImagePath = seal1ImagePath;
        });
      }
    }

    if (containerHarbor!.seal2.imagePath != null) {
      final seal2ImagePath =
          await _uploadImage(containerHarbor!.seal2.imagePath!);
      if (seal2ImagePath != null) {
        setState(() {
          containerHarbor!.seal2.savedImagePath = seal2ImagePath;
        });
      }
    }
  }

  Future<void> _uploadAdditionalImages() async {
    List<String> uploadedPaths = [];
    for (var image in additionalImages) {
      final path = await _uploadImage(image.path);
      if (path != null) {
        uploadedPaths.add(path);
      }
    }
    setState(() {
      containerHarbor!.additionalImages = uploadedPaths;
    });
  }

  void _updateContainerHarborData() {
    if (containerHarbor == null) return;
  }

  Future<void> _sendDataViaMqtt() async {
    final jsonData = containerHarbor!.toJson();
    print("-----------jsonData: $jsonData");
    await mqttService.sendMessage(_baseTopic, jsonData);
  }

  Future<void> _showSuccessDialog(AppLocalizations l10n) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(l10n.success,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: Text(l10n.dataSent),
        actions: [
          TextButton(
            onPressed: () {
              widget.onTaskFinish();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: AppTheme.actionButtonStyle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.ok,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // void _showWarningDialog(AppLocalizations l10n) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Row(
  //         children: [
  //           const Icon(Icons.warning, color: Colors.orange),
  //           const SizedBox(width: 8),
  //           Expanded(
  //             child: Text(l10n.warning,
  //                 maxLines: 2, overflow: TextOverflow.ellipsis),
  //           ),
  //         ],
  //       ),
  //       content: Text(l10n.fillSealData),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: Text(l10n.ok),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _showErrorDialog(AppLocalizations l10n, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(l10n.error,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        content: Text(l10n.sendFailed(error)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
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
          _buildHeader(l10n),
          const SizedBox(height: 16),
          _buildImageList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
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
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildImageList() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (additionalImages.length < AppConstants.maxAdditionalImages)
            _buildAddImageButton(),
          ...additionalImages.asMap().entries.map(_buildImageTile),
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return Container(
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
    );
  }

  Widget _buildImageTile(MapEntry<int, XFile> entry) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => _showImageDialog(entry.value),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(entry.value.path),
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
              icon: const Icon(Icons.delete, color: Colors.white, size: 20),
              onPressed: () => _removeImage(entry.key),
            ),
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
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(l10n.sealScanner,
              maxLines: 2, overflow: TextOverflow.ellipsis),
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.send), onPressed: _handleSend),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (containerHarbor != null) ...[
                Container(
                    margin: const EdgeInsets.only(top: 16),
                    height: MediaQuery.of(context).size.height *
                        AppConstants.imagePickerHeight,
                    child: widget.task.containerCode2 == null ||
                            widget.task.containerCode2!.isEmpty
                        ? SealContainerPicker(
                            key: const ValueKey('container1'),
                            index: 1,
                            containerCode: _container1Controller.text,
                            syncSeal: widget.task.syncSeal1,
                            seal: containerHarbor!.seal1.copyWith(
                              cargoType:
                                  containerHarbor!.seal1.cargoType.isEmpty
                                      ? widget.task.cargoType1
                                      : containerHarbor!.seal1.cargoType,
                            ),
                            onSealChanged: (updatedSeal) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  containerHarbor = containerHarbor!
                                      .copyWith(seal1: updatedSeal);
                                });
                              });
                            },
                            onEditContainer: () =>
                                _editContainerCode(context, true),
                          )
                        : widget.task.containerCode1 == null ||
                                widget.task.containerCode1!.isEmpty
                            ? SealContainerPicker(
                                key: const ValueKey('container2'),
                                index: 2,
                                containerCode: _container2Controller.text,
                                syncSeal: widget.task.syncSeal2,
                                seal: containerHarbor!.seal2.copyWith(
                                  cargoType:
                                      containerHarbor!.seal2.cargoType.isEmpty
                                          ? widget.task.cargoType2
                                          : containerHarbor!.seal2.cargoType,
                                ),
                                onSealChanged: (updatedSeal) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    setState(() {
                                      containerHarbor = containerHarbor!
                                          .copyWith(seal2: updatedSeal);
                                    });
                                  });
                                },
                                onEditContainer: () =>
                                    _editContainerCode(context, false),
                              )
                            : PageView(
                                controller: _pageController,
                                children: [
                                  SealContainerPicker(
                                    key: const ValueKey('container1'),
                                    index: 1,
                                    containerCode: _container1Controller.text,
                                    syncSeal: widget.task.syncSeal1,
                                    seal: containerHarbor!.seal1.copyWith(
                                      cargoType: containerHarbor!
                                              .seal1.cargoType.isEmpty
                                          ? widget.task.cargoType1
                                          : containerHarbor!.seal1.cargoType,
                                    ),
                                    onSealChanged: (updatedSeal) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        setState(() {
                                          containerHarbor = containerHarbor!
                                              .copyWith(seal1: updatedSeal);
                                        });
                                      });
                                    },
                                    onEditContainer: () =>
                                        _editContainerCode(context, true),
                                  ),
                                  SealContainerPicker(
                                    key: const ValueKey('container2'),
                                    index: 2,
                                    containerCode: _container2Controller.text,
                                    syncSeal: widget.task.syncSeal2,
                                    seal: containerHarbor!.seal2.copyWith(
                                      cargoType: containerHarbor!
                                              .seal2.cargoType.isEmpty
                                          ? widget.task.cargoType2
                                          : containerHarbor!.seal2.cargoType,
                                    ),
                                    onSealChanged: (updatedSeal) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        setState(() {
                                          containerHarbor = containerHarbor!
                                              .copyWith(seal2: updatedSeal);
                                        });
                                      });
                                    },
                                    onEditContainer: () =>
                                        _editContainerCode(context, false),
                                  ),
                                ],
                              )),
              ],
              _buildAdditionalInfo(),
            ],
          ),
        ),
      ),
    );
  }
}
