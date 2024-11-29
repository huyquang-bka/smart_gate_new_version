import 'package:smart_gate_new_version/features/seal/domain/models/seal.dart';

class ContainerHarbor {
  final String checkPointId;
  final String userID;
  final String fullName;
  final Seal seal1;
  final Seal seal2;
  String description;
  List<String> additionalImages;

  ContainerHarbor({
    required this.checkPointId,
    required this.userID,
    required this.fullName,
    this.description = '',
    List<String>? additionalImages,
  })  : seal1 = Seal(),
        seal2 = Seal(),
        additionalImages = additionalImages ?? [];

  Map<String, dynamic> toJson() {
    return {
      "CheckPointId": int.parse(checkPointId),
      "USERID": int.parse(userID),
      "FULLNAME": fullName,
      "SEAL1": seal1.toJson(),
      "SEAL2": seal2.toJson(),
      "DESCRIPTION": description,
      "ADDITIONIMAGES": additionalImages,
    };
  }

  ContainerHarbor copyWith({
    String? checkPointId,
    String? userID,
    String? fullName,
    Seal? seal1,
    Seal? seal2,
    String? description,
    List<String>? additionalImages,
  }) {
    return ContainerHarbor(
      checkPointId: checkPointId ?? this.checkPointId,
      userID: userID ?? this.userID,
      fullName: fullName ?? this.fullName,
      description: description ?? this.description,
      additionalImages: additionalImages ?? this.additionalImages,
    )
      ..seal1.imagePath = seal1?.imagePath ?? this.seal1.imagePath
      ..seal1.sealNumber1 = seal1?.sealNumber1 ?? this.seal1.sealNumber1
      ..seal1.sealNumber2 = seal1?.sealNumber2 ?? this.seal1.sealNumber2
      ..seal1.isDangerous = seal1?.isDangerous ?? this.seal1.isDangerous
      ..seal2.imagePath = seal2?.imagePath ?? this.seal2.imagePath
      ..seal2.sealNumber1 = seal2?.sealNumber1 ?? this.seal2.sealNumber1
      ..seal2.sealNumber2 = seal2?.sealNumber2 ?? this.seal2.sealNumber2
      ..seal2.isDangerous = seal2?.isDangerous ?? this.seal2.isDangerous;
  }

  bool get isComplete {
    return seal1.imagePath != null && seal1.sealNumber1.isNotEmpty;
  }
}
