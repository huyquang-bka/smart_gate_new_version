import 'package:clean_store_app/core/configs/api_route.dart';
import 'package:clean_store_app/core/configs/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class ImagePickerWidget extends StatefulWidget {
  final int index;
  final String? imagePath;
  final String seal1Number;
  final String seal2Number;
  final bool isDangerous;
  final Function(String?) onImageChanged;
  final Function(String) onSeal1NumberChanged;
  final Function(String) onSeal2NumberChanged;
  final Function(bool) onDangerousChanged;

  const ImagePickerWidget({
    super.key,
    required this.index,
    this.imagePath,
    required this.seal1Number,
    required this.seal2Number,
    required this.isDangerous,
    required this.onImageChanged,
    required this.onSeal1NumberChanged,
    required this.onSeal2NumberChanged,
    required this.onDangerousChanged,
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
    return GestureDetector(
      onTap: () {
        _seal1Focus.unfocus();
        _seal2Focus.unfocus();
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Stack(
              children: [
                Center(
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: image == null
                        ? Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 64,
                              color: AppTheme.primaryColor.withOpacity(0.5),
                            ),
                          )
                        : GestureDetector(
                            onTap: () => _showImagePreview(context),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                image!,
                                fit: BoxFit.contain,
                                // width: double.infinity,
                              ),
                            ),
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
                  ),
                  child: IconButton(
                    onPressed: _isLoading
                        ? null
                        : () => _getImageFromSource(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    tooltip: 'Take Photo',
                    color: AppTheme.primaryColor,
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
                    tooltip: 'Choose from Gallery',
                    color: AppTheme.primaryColor,
                  ),
                ),
                if (image != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red,
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                image = null;
                                _seal1Controller.clear();
                                _seal2Controller.clear();
                              });
                              widget.onImageChanged(null);
                              widget.onSeal1NumberChanged('');
                              widget.onSeal2NumberChanged('');
                            },
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete Photo',
                      color: Colors.red,
                    ),
                  ),
                ],
                const Spacer(),
                Row(
                  children: [
                    const Text('Dangerous'),
                    Switch(
                      value: widget.isDangerous,
                      onChanged: _isLoading ? null : widget.onDangerousChanged,
                      activeColor: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _seal1Controller,
              focusNode: _seal1Focus,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                labelText: 'Seal 1',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.qr_code),
              ),
              onChanged: widget.onSeal1NumberChanged,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _seal2Controller,
              focusNode: _seal2Focus,
              enabled: !_isLoading,
              decoration: const InputDecoration(
                labelText: 'Seal 2',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.qr_code),
              ),
              onChanged: widget.onSeal2NumberChanged,
            ),
          ],
        ),
      ),
    );
  }
}
