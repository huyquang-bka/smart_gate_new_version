import 'package:clean_store_app/features/seal/domain/models/seal.dart';

class ContainerHarbor {
  final String checkPointId;
  final String userID;
  final String fullName;
  final Seal seal1;
  final Seal seal2;

  ContainerHarbor({
    required this.checkPointId,
    required this.userID,
    required this.fullName,
  })  : seal1 = Seal(),
        seal2 = Seal();

  Map<String, dynamic> toJson() {
    return {
      "CheckPointId": checkPointId,
      "userID": userID,
      "fullName": fullName,
      "seal1": seal1.toJson(),
      "seal2": seal2.toJson(),
    };
  }

  ContainerHarbor copyWith({
    String? checkPointId,
    String? userID,
    String? fullName,
    Seal? seal1,
    Seal? seal2,
  }) {
    return ContainerHarbor(
      checkPointId: checkPointId ?? this.checkPointId,
      userID: userID ?? this.userID,
      fullName: fullName ?? this.fullName,
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
