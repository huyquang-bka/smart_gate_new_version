import 'package:smart_gate_new_version/features/seal/domain/models/seal.dart';
import 'package:smart_gate_new_version/features/seal/widgets/image_picker.dart';
import 'package:flutter/material.dart';

class SealContainerPicker extends StatelessWidget {
  final int index;
  final String containerCode;
  final Seal seal;
  final Function(Seal) onSealChanged;
  final Function() onEditContainer;

  const SealContainerPicker({
    super.key,
    required this.index,
    required this.containerCode,
    required this.seal,
    required this.onSealChanged,
    required this.onEditContainer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.withOpacity(0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                containerCode.toUpperCase(),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                onPressed: onEditContainer,
                icon: const Icon(
                  Icons.edit,
                  color: Colors.black,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
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
