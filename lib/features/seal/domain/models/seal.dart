class Seal {
  String? imagePath;
  String savedImagePath;
  String sealNumber1;
  String sealNumber2;
  bool isDangerous;

  Seal({
    this.imagePath,
    this.savedImagePath = '',
    this.sealNumber1 = '',
    this.sealNumber2 = '',
    this.isDangerous = false,
  });

  Map<String, dynamic>? toJson() {
    String sealNumber =
        sealNumber1 + (sealNumber2.isNotEmpty ? "/$sealNumber2" : '');
    if (sealNumber.isEmpty || savedImagePath.isEmpty) {
      return null;
    }
    return {
      "list": sealNumber,
      "image": savedImagePath,
      "isDangerous": isDangerous,
    };
  }

  Seal copyWith({
    String? imagePath,
    String? savedImagePath,
    String? sealNumber1,
    String? sealNumber2,
    bool? isDangerous,
  }) {
    return Seal(
      imagePath: imagePath ?? this.imagePath,
      savedImagePath: savedImagePath ?? this.savedImagePath,
      sealNumber1: sealNumber1 ?? this.sealNumber1,
      sealNumber2: sealNumber2 ?? this.sealNumber2,
      isDangerous: isDangerous ?? this.isDangerous,
    );
  }
}
