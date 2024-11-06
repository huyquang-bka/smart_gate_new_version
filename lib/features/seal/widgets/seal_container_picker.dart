import 'package:clean_store_app/core/configs/app_theme.dart';
import 'package:clean_store_app/features/seal/domain/models/seal.dart';
import 'package:clean_store_app/features/seal/widgets/image_picker.dart';
import 'package:flutter/material.dart';

class SealContainerPicker extends StatelessWidget {
  final int index;
  final Seal seal;
  final Function(Seal) onSealChanged;

  const SealContainerPicker({
    super.key,
    required this.index,
    required this.seal,
    required this.onSealChanged,
  });

  void _updateSeal({
    String? imagePath,
    String? sealNumber1,
    String? sealNumber2,
    bool? isDangerous,
  }) {
    onSealChanged(
      seal.copyWith(
        imagePath: imagePath,
        sealNumber1: sealNumber1,
        sealNumber2: sealNumber2,
        isDangerous: isDangerous,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Container $index',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ImagePickerWidget(
          index: index,
          imagePath: seal.imagePath,
          seal1Number: seal.sealNumber1,
          seal2Number: seal.sealNumber2,
          isDangerous: seal.isDangerous,
          onImageChanged: (path) => _updateSeal(imagePath: path),
          onSeal1NumberChanged: (number) => _updateSeal(sealNumber1: number),
          onSeal2NumberChanged: (number) => _updateSeal(sealNumber2: number),
          onDangerousChanged: (value) => _updateSeal(isDangerous: value),
        ),
      ],
    );
  }
}
