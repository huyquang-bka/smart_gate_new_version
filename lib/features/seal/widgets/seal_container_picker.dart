import 'package:smart_gate_new_version/features/seal/domain/models/seal.dart';
import 'package:smart_gate_new_version/features/seal/widgets/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SealContainerPicker extends StatelessWidget {
  final int index;
  final String containerCode;
  final Seal seal;
  final Function(Seal) onSealChanged;
  final Function() onEditContainer;
  final String? syncSeal;

  const SealContainerPicker({
    super.key,
    required this.index,
    required this.containerCode,
    required this.seal,
    required this.onSealChanged,
    required this.onEditContainer,
    this.syncSeal,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
          child: Column(
            children: [
              Row(
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
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Sync seal
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
            color: Colors.orange.withOpacity(0.4),
          ),
          child: Text(
            l10n.syncSealLabel(syncSeal ?? '?'),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
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
