import 'dart:io';

import 'package:clean_store_app/core/configs/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  void dispose() {
    _seal1Controller.dispose();
    _seal2Controller.dispose();
    _seal1Focus.dispose();
    _seal2Focus.dispose();
    super.dispose();
  }

  Future<void> _getImageFromSource(ImageSource source) async {
    try {
      setState(() {
        _isLoading = true;
      });
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        image = File(pickedFile.path);
        widget.onImageChanged(pickedFile.path);
      }
    } catch (e) {
      print('Error picking image: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
            // Image container with loading overlay
            Stack(
              children: [
                Container(
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
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            image!,
                            fit: BoxFit.cover,
                            width: double.infinity,
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
            // Action buttons
            Row(
              children: [
                IconButton(
                  onPressed: _isLoading
                      ? null
                      : () => _getImageFromSource(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  tooltip: 'Take Photo',
                  color: AppTheme.primaryColor,
                ),
                IconButton(
                  onPressed: _isLoading
                      ? null
                      : () => _getImageFromSource(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  tooltip: 'Choose from Gallery',
                  color: AppTheme.primaryColor,
                ),
                if (image != null)
                  IconButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              image = null;
                            });
                            widget.onImageChanged(null);
                          },
                    icon: const Icon(Icons.delete),
                    tooltip: 'Delete Photo',
                    color: Colors.red,
                  ),
                const Spacer(),
                // Dangerous toggle
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
            // Seal number inputs
            TextField(
              controller: _seal1Controller,
              focusNode: _seal1Focus,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Seal Number 1',
                border: const OutlineInputBorder(),
                suffixIcon: Icon(
                  Icons.qr_code,
                  color: AppTheme.primaryColor,
                ),
              ),
              onChanged: widget.onSeal1NumberChanged,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _seal2Controller,
              focusNode: _seal2Focus,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Seal Number 2',
                border: const OutlineInputBorder(),
                suffixIcon: Icon(
                  Icons.qr_code,
                  color: AppTheme.primaryColor,
                ),
              ),
              onChanged: widget.onSeal2NumberChanged,
            ),
          ],
        ),
      ),
    );
  }
}