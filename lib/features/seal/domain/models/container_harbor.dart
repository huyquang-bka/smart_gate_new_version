import 'package:smart_gate_new_version/features/seal/domain/models/seal.dart';

class ContainerHarbor {
  final String checkPointId;
  final String userID;
  final String fullName;
  Seal seal1;
  Seal seal2;
  List<String> additionalImages;

  ContainerHarbor({
    required this.checkPointId,
    required this.userID,
    required this.fullName,
    List<String>? additionalImages,
  })  : seal1 = Seal(),
        seal2 = Seal(),
        additionalImages = additionalImages ?? [];

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'CheckPointId': int.tryParse(checkPointId) ?? 0,
      'USERID': int.tryParse(userID) ?? 0,
      'FULLNAME': fullName,
    };

    // Add seal1 data if it exists
    final seal1Json = seal1.toJson();
    if (seal1Json != null) {
      data['SEAL1'] = seal1Json;
    } else {
      data['SEAL1'] = null;
    }

    // Add seal2 data if it exists
    final seal2Json = seal2.toJson();
    if (seal2Json != null) {
      data['SEAL2'] = seal2Json;
    } else {
      data['SEAL2'] = null;
    }

    // Only include additional images that exist
    if (additionalImages.isNotEmpty) {
      data['ADDITIONIMAGES'] = additionalImages;
    }
    data["DESCRIPTION"] = null;

    return data;
  }

  ContainerHarbor copyWith({
    String? checkPointId,
    String? userID,
    String? fullName,
    Seal? seal1,
    Seal? seal2,
    List<String>? additionalImages,
  }) {
    return ContainerHarbor(
      checkPointId: checkPointId ?? this.checkPointId,
      userID: userID ?? this.userID,
      fullName: fullName ?? this.fullName,
      additionalImages: additionalImages ?? this.additionalImages,
    )
      ..seal1.imagePath = seal1?.imagePath ?? this.seal1.imagePath
      ..seal1.sealNumber1 = seal1?.sealNumber1 ?? this.seal1.sealNumber1
      ..seal1.sealNumber2 = seal1?.sealNumber2 ?? this.seal1.sealNumber2
      ..seal1.cargoType = seal1?.cargoType ?? this.seal1.cargoType
      ..seal1.description = seal1?.description ?? this.seal1.description
      ..seal1.savedImagePath =
          seal1?.savedImagePath ?? this.seal1.savedImagePath
      ..seal2.imagePath = seal2?.imagePath ?? this.seal2.imagePath
      ..seal2.sealNumber1 = seal2?.sealNumber1 ?? this.seal2.sealNumber1
      ..seal2.sealNumber2 = seal2?.sealNumber2 ?? this.seal2.sealNumber2
      ..seal2.cargoType = seal2?.cargoType ?? this.seal2.cargoType
      ..seal2.description = seal2?.description ?? this.seal2.description
      ..seal2.savedImagePath =
          seal2?.savedImagePath ?? this.seal2.savedImagePath;
  }

  bool get isComplete {
    return seal1.imagePath != null && seal1.sealNumber1.isNotEmpty;
  }

  @override
  String toString() {
    return "ContainerHarbor: $checkPointId $userID $fullName $seal1 $seal2 $additionalImages";
  }
}
