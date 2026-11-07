class TypeDocument {
  const TypeDocument({
    required this.id,
    required this.intitule,
    required this.initSeparateur,
  });

  final int id;
  final String intitule;
  final String initSeparateur;

  factory TypeDocument.fromJson(Map<String, dynamic> json) {
    return TypeDocument(
      id: json['id'] as int,
      intitule: json['intitule'] as String,
      initSeparateur: json['initSeparateur'] as String,
    );
  }
}

class MatriceElement {
  const MatriceElement({
    required this.fkTypeDocument,
    required this.element,
    required this.crypto,
  });

  final int fkTypeDocument;
  final String element;
  final String crypto;

  factory MatriceElement.fromJson(Map<String, dynamic> json) {
    return MatriceElement(
      fkTypeDocument: json['fk'] as int,
      element: _parseElement(json['element'], json['crypto'] as String),
      crypto: json['crypto'] as String,
    );
  }

  static String _parseElement(Object? raw, String crypto) {
    final value = raw is String ? raw : raw?.toString() ?? '';
    if (value.isEmpty && crypto == 'nj39') {
      return ' ';
    }
    return value;
  }
}

class OrdreChamps {
  const OrdreChamps({
    required this.fkTypeDocument,
    required this.ordre,
    required this.champs,
  });

  final int fkTypeDocument;
  final int ordre;
  final String champs;

  factory OrdreChamps.fromJson(Map<String, dynamic> json) {
    return OrdreChamps(
      fkTypeDocument: json['fk'] as int,
      ordre: json['ordre'] as int,
      champs: json['champs'] as String,
    );
  }
}

class MatriceSeparateur {
  const MatriceSeparateur({
    required this.fkTypeDocument,
    required this.champ,
    required this.separateur,
    required this.crypto,
  });

  final int fkTypeDocument;
  final String champ;
  final String separateur;
  final String crypto;

  factory MatriceSeparateur.fromJson(Map<String, dynamic> json) {
    return MatriceSeparateur(
      fkTypeDocument: json['fk'] as int,
      champ: json['champ'] as String,
      separateur: json['separateur'] as String,
      crypto: json['crypto'] as String,
    );
  }
}

class CryptoMatriceData {
  const CryptoMatriceData({
    required this.typeDocument,
    required this.matriceElement,
    required this.ordreChamps,
    required this.matriceSeparateur,
    required this.cryptoParElement,
    required this.elementParCrypto,
  });

  final List<TypeDocument> typeDocument;
  final List<MatriceElement> matriceElement;
  final List<OrdreChamps> ordreChamps;
  final List<MatriceSeparateur> matriceSeparateur;
  final Map<String, String> cryptoParElement;
  final Map<String, String> elementParCrypto;

  factory CryptoMatriceData.fromJson(Map<String, dynamic> json) {
    final matriceElement = (json['matriceElement'] as List<dynamic>)
        .map((item) => MatriceElement.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    return CryptoMatriceData(
      typeDocument: (json['typeDocument'] as List<dynamic>)
          .map((item) => TypeDocument.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      matriceElement: matriceElement,
      ordreChamps: (json['ordreChamps'] as List<dynamic>)
          .map((item) => OrdreChamps.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      matriceSeparateur: (json['matriceSeparateur'] as List<dynamic>)
          .map(
            (item) => MatriceSeparateur.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      cryptoParElement: {
        for (final ligne in matriceElement) ligne.element: ligne.crypto,
      },
      elementParCrypto: {
        for (final ligne in matriceElement) ligne.crypto: ligne.element,
      },
    );
  }
}
