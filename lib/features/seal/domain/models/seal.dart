class Seal {
  String? imagePath;
  String savedImagePath;
  String sealNumber1;
  String sealNumber2;
  String cargoType;
  String description;

  Seal({
    this.imagePath,
    this.savedImagePath = '',
    this.sealNumber1 = '',
    this.sealNumber2 = '',
    this.cargoType = '',
    this.description = '',
  });

  void clearImage() {
    imagePath = null;
    savedImagePath = '';
  }

  Map<String, dynamic>? toJson() {
    print("-----------Seal: $sealNumber1 $sealNumber2 $cargoType");
    String sealNumber =
        sealNumber1 + (sealNumber2.isNotEmpty ? "/$sealNumber2" : '');
    if (sealNumber.isEmpty || (imagePath == null && savedImagePath.isEmpty)) {
      return null;
    }
    return {
      "list": sealNumber,
      "image": savedImagePath,
      "cargoType": cargoType,
      "description": description,
    };
  }

  Seal copyWith({
    String? imagePath,
    String? savedImagePath,
    String? sealNumber1,
    String? sealNumber2,
    String? cargoType,
    String? description,
  }) {
    return Seal(
      imagePath: imagePath ?? this.imagePath,
      savedImagePath: savedImagePath ?? this.savedImagePath,
      sealNumber1: sealNumber1 ?? this.sealNumber1,
      sealNumber2: sealNumber2 ?? this.sealNumber2,
      cargoType: cargoType ?? this.cargoType,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'Seal(imagePath: $imagePath, savedImagePath: $savedImagePath, sealNumber1: $sealNumber1, sealNumber2: $sealNumber2, cargoType: $cargoType, description: $description)';
  }
}
