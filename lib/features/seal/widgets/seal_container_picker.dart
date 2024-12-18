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
    Seal currentSeal = seal;
    return Column(
      children: [
        // Container code
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
        // Seal image
        ImagePickerWidget(
          index: index,
          imagePath: seal.imagePath,
          seal1Number: seal.sealNumber1,
          seal2Number: seal.sealNumber2,
          cargoType: seal.cargoType,
          onImageChanged: (path) {
            currentSeal.imagePath = path;
            onSealChanged(currentSeal);
          },
          onSeal1NumberChanged: (number) {
            currentSeal.sealNumber1 = number;
            onSealChanged(currentSeal);
          },
          onSeal2NumberChanged: (number) {
            currentSeal.sealNumber2 = number;
            onSealChanged(currentSeal);
          },
          onCargoTypeChanged: (cargoType) {
            currentSeal.cargoType = cargoType;
            onSealChanged(currentSeal);
          },
        ),
      ],
    );
  }
}
