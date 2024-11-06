import 'dart:convert';
import 'dart:io';

class Seal {
  String? imagePath;
  String sealNumber1;
  String sealNumber2;
  bool isDangerous;

  Seal({
    this.imagePath,
    this.sealNumber1 = '',
    this.sealNumber2 = '',
    this.isDangerous = false,
  });

  Map<String, dynamic> toJson() {
    return {
      "list": sealNumber1 + (sealNumber2.isNotEmpty ? "/$sealNumber2" : ''),
      "image": imagePath?.isEmpty ?? true
          ? null
          : base64Encode(File(imagePath!).readAsBytesSync()),
      "isDangerous": isDangerous,
    };
  }

  Seal copyWith({
    String? imagePath,
    String? sealNumber1,
    String? sealNumber2,
    bool? isDangerous,
  }) {
    return Seal(
      imagePath: imagePath ?? this.imagePath,
      sealNumber1: sealNumber1 ?? this.sealNumber1,
      sealNumber2: sealNumber2 ?? this.sealNumber2,
      isDangerous: isDangerous ?? this.isDangerous,
    );
  }
}
