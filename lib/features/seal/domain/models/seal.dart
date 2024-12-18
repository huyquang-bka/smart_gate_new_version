class Seal {
  String? imagePath;
  String savedImagePath;
  String sealNumber1;
  String sealNumber2;
  String cargoType;
  Seal({
    this.imagePath,
    this.savedImagePath = '',
    this.sealNumber1 = '',
    this.sealNumber2 = '',
    this.cargoType = '',
  });

  Map<String, dynamic>? toJson() {
    print("-----------Seal: $sealNumber1 $sealNumber2 $cargoType");
    String sealNumber =
        sealNumber1 + (sealNumber2.isNotEmpty ? "/$sealNumber2" : '');
    if (sealNumber.isEmpty || savedImagePath.isEmpty) {
      return null;
    }
    return {
      "list": sealNumber,
      "image": savedImagePath,
      "cargoType": cargoType,
    };
  }

  Seal copyWith({
    String? imagePath,
    String? savedImagePath,
    String? sealNumber1,
    String? sealNumber2,
    String? cargoType,
  }) {
    return Seal(
      imagePath: imagePath ?? this.imagePath,
      savedImagePath: savedImagePath ?? this.savedImagePath,
      sealNumber1: sealNumber1 ?? this.sealNumber1,
      sealNumber2: sealNumber2 ?? this.sealNumber2,
      cargoType: cargoType ?? this.cargoType,
    );
  }

  @override
  String toString() {
    return 'Seal(imagePath: $imagePath, savedImagePath: $savedImagePath, sealNumber1: $sealNumber1, sealNumber2: $sealNumber2, cargoType: $cargoType)';
  }
}
