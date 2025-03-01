import 'package:smart_gate_new_version/core/configs/api_route.dart';
import 'package:smart_gate_new_version/core/configs/app_constants.dart';
import 'package:smart_gate_new_version/core/configs/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:convert';
import 'dart:io';

class ImagePickerWidget extends StatefulWidget {
  final int index;
  final String? imagePath;
  final String seal1Number;
  final String seal2Number;
  final String cargoType;
  final Function(String?) onImageChanged;
  final Function(String) onSeal1NumberChanged;
  final Function(String) onSeal2NumberChanged;
  final Function(String) onCargoTypeChanged;

  const ImagePickerWidget({
    super.key,
    required this.index,
    this.imagePath,
    required this.seal1Number,
    required this.seal2Number,
    required this.cargoType,
    required this.onImageChanged,
    required this.onSeal1NumberChanged,
    required this.onSeal2NumberChanged,
    required this.onCargoTypeChanged,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();
  File? image;
  final TextEditingController _seal1Controller = TextEditingController();
  final TextEditingController _seal2Controller = TextEditingController();
  final FocusNode _seal1Focus = FocusNode();
  final FocusNode _seal2Focus = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _seal1Controller.text = widget.seal1Number;
    _seal2Controller.text = widget.seal2Number;
    if (widget.imagePath != null) {
      image = File(widget.imagePath!);
    }
    widget.onCargoTypeChanged(widget.cargoType);
  }

  @override
  void didUpdateWidget(ImagePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imagePath != oldWidget.imagePath) {
      setState(() {
        image = widget.imagePath != null ? File(widget.imagePath!) : null;
      });
    }
    if (widget.seal1Number != oldWidget.seal1Number) {
      _seal1Controller.text = widget.seal1Number;
    }
    if (widget.seal2Number != oldWidget.seal2Number) {
      _seal2Controller.text = widget.seal2Number;
    }
    if (widget.cargoType != oldWidget.cargoType) {
      widget.onCargoTypeChanged(widget.cargoType);
    }
  }

  @override
  void dispose() {
    _seal1Controller.dispose();
    _seal2Controller.dispose();
    _seal1Focus.dispose();
    _seal2Focus.dispose();
    super.dispose();
  }

  Future<void> _textRecognize(File imageFile) async {
    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(Url.postSeal),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final response = await request.send().timeout(
            const Duration(seconds: 3),
          );
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonData = jsonDecode(responseBody);
        final recognizedText = jsonData['text'].toString().toUpperCase();

        setState(() {
          _seal1Controller.text = recognizedText;
        });
        widget.onSeal1NumberChanged(recognizedText);
      } else {
        debugPrint(
            "Failed to recognize text. Status code: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error occurred during text recognition: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getImageFromSource(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, maxHeight: 1000);
      if (file != null) {
        final imageFile = File(file.path);

        setState(() {
          image = imageFile;
        });

        widget.onImageChanged(imageFile.path);
        await _textRecognize(imageFile);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showImagePreview(BuildContext context) {
    if (image != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4,
                    child: Image.file(
                      image!,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => Navigator.pop(context),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Center(
                  child: Container(
                    height: 200,
                    decoration: image == null
                        ? BoxDecoration(
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.5),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    child: image == null
                        ? Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 64,
                              color: AppTheme.primaryColor.withOpacity(0.5),
                            ),
                          )
                        : Stack(
                            children: [
                              GestureDetector(
                                onTap: () => _showImagePreview(context),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    image!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      image = null;
                                      _seal1Controller.clear();
                                      _seal2Controller.clear();
                                    });
                                    widget.onImageChanged(null);
                                    widget.onSeal1NumberChanged('');
                                    widget.onSeal2NumberChanged('');
                                  },
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (_isLoading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryColor,
                      width: 1,
                    ),
                    color: AppTheme.primaryColor,
                  ),
                  child: IconButton(
                    onPressed: _isLoading
                        ? null
                        : () => _getImageFromSource(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    tooltip: l10n.takePhoto,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryColor,
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    onPressed: _isLoading
                        ? null
                        : () => _getImageFromSource(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    tooltip: l10n.chooseFromGallery,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCargoTypeDropdown(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _seal1Controller,
              focusNode: _seal1Focus,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: l10n.seal1,
                border: const OutlineInputBorder(),
              ),
              onChanged: widget.onSeal1NumberChanged,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _seal2Controller,
              focusNode: _seal2Focus,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: l10n.seal2,
                border: const OutlineInputBorder(),
              ),
              onChanged: widget.onSeal2NumberChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCargoTypeDropdown(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<String>(
      value: widget.cargoType,
      decoration: InputDecoration(
        labelText: l10n.cargoTypeLabel,
        border: const OutlineInputBorder(),
      ),
      items: AppConstants.defaultCargoTypeCode.map((String code) {
        return DropdownMenuItem<String>(
          value: code,
          child: Text('$code - ${l10n.cargoType(code)}'),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          widget.onCargoTypeChanged(newValue);
        }
      },
    );
  }
}
