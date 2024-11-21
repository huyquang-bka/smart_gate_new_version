import 'package:smart_gate_new_version/core/configs/app_theme.dart';
import 'package:smart_gate_new_version/features/seal/domain/models/seal.dart';
import 'package:smart_gate_new_version/features/seal/widgets/image_picker.dart';
import 'package:flutter/material.dart';

class SealContainerPicker extends StatelessWidget {
  final int index;
  final String containerCode;
  final Seal seal;
  final Function(Seal) onSealChanged;

  const SealContainerPicker({
    super.key,
    required this.index,
    required this.containerCode,
    required this.seal,
    required this.onSealChanged,
  });

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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                containerCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ImagePickerWidget(
          index: index,
          imagePath: seal.imagePath,
          seal1Number: seal.sealNumber1,
          seal2Number: seal.sealNumber2,
          isDangerous: seal.isDangerous,
          onImageChanged: (path) => onSealChanged(
            seal.copyWith(imagePath: path),
          ),
          onSeal1NumberChanged: (number) => onSealChanged(
            seal.copyWith(sealNumber1: number),
          ),
          onSeal2NumberChanged: (number) => onSealChanged(
            seal.copyWith(sealNumber2: number),
          ),
          onDangerousChanged: (value) => onSealChanged(
            seal.copyWith(isDangerous: value),
          ),
        ),
      ],
    );
  }
}
