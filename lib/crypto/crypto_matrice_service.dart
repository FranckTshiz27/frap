import 'dart:convert';

import 'package:mobile_fp/crypto/crypto_matrice_models.dart';
import 'package:mobile_fp/crypto/crypto_matrice_repository.dart';

class ChiffrementTexteResult {
  const ChiffrementTexteResult({
    required this.crypto,
    required this.ignores,
  });

  final String crypto;
  final List<String> ignores;
}

class ChiffrementDetail {
  const ChiffrementDetail({
    required this.champ,
    required this.brut,
    required this.crypto,
    required this.ignores,
  });

  final String champ;
  final String brut;
  final String crypto;
  final List<String> ignores;
}

class ChiffrementFicheResult {
  const ChiffrementFicheResult({
    required this.resultat,
    required this.details,
    required this.chaineLogique,
  });

  final String resultat;
  final List<ChiffrementDetail> details;
  final String chaineLogique;
}

class DechiffrementDetail {
  const DechiffrementDetail({
    required this.champ,
    required this.crypto,
    required this.texte,
  });

  final String champ;
  final String crypto;
  final String texte;
}

class DechiffrementFicheResult {
  const DechiffrementFicheResult({
    required this.valeurs,
    required this.details,
    required this.chaineLogique,
  });

  final Map<String, String> valeurs;
  final List<DechiffrementDetail> details;
  final String chaineLogique;
}

abstract final class CryptoMatriceService {
  static CryptoMatriceData get _data => CryptoMatriceRepository.data;

  static Map<String, String> get _cryptoParElement => _data.cryptoParElement;

  static String preparerPayloadScan(String rawValue) {
    final trimmed = rawValue.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    try {
      final decoded = utf8.decode(base64.decode(trimmed));
      if (_estPayloadChiffre(decoded)) {
        return decoded;
      }
    } on FormatException {
      // Payload déjà en clair ou Base64 invalide.
    }

    return trimmed;
  }

  static bool _estPayloadChiffre(String value) {
    final premierSeparateur = _separateurPourChamp('type')?.crypto;
    return premierSeparateur != null && value.contains(premierSeparateur);
  }

  static bool estPayloadScanValide(String rawValue) {
    final prepared = preparerPayloadScan(rawValue);
    return _estPayloadChiffre(prepared);
  }

  static DechiffrementFicheResult dechiffrerFicheScan(String scannedValue) {
    return dechiffrerFiche(preparerPayloadScan(scannedValue));
  }

  static List<String> getNomsChampsOrdonnes({int fkTypeDocument = 1}) {
    final items = _data.ordreChamps
        .where((item) => item.fkTypeDocument == fkTypeDocument)
        .toList()
      ..sort((a, b) => a.ordre.compareTo(b.ordre));
    return items.map((item) => item.champs).toList();
  }

  static bool _estEspace(String char) {
    if (char.isEmpty) {
      return false;
    }

    if (char == ' ') {
      return true;
    }

    const espacesEtendus = {0x00A0, 0x2007, 0x202F, 0x2009, 0x200A};
    return char.length == 1 && espacesEtendus.contains(char.codeUnitAt(0));
  }

  static String _normaliserElement(String char) {
    if (_estEspace(char)) {
      return ' ';
    }
    return char.toUpperCase();
  }

  static String chiffrerCaractere(String char) {
    if (char.isEmpty) {
      return '';
    }

    return _cryptoParElement[_normaliserElement(char)] ?? '';
  }

  static ChiffrementTexteResult chiffrerTexte(String texte) {
    final ignores = <String>[];
    final buffer = StringBuffer();

    for (final c in texte.runes.map(String.fromCharCode)) {
      final bloc = chiffrerCaractere(c);
      if (bloc.isNotEmpty) {
        buffer.write(bloc);
      } else if (_estEspace(c)) {
        final espace = _cryptoParElement[' '];
        if (espace != null) {
          buffer.write(espace);
        }
      } else if (c.trim().isNotEmpty) {
        ignores.add(c);
      }
    }

    return ChiffrementTexteResult(
      crypto: buffer.toString(),
      ignores: ignores,
    );
  }

  static MatriceSeparateur? _separateurPourChamp(String champ) {
    for (final sep in _data.matriceSeparateur) {
      if (sep.champ == champ) {
        return sep;
      }
    }
    return null;
  }

  static ChiffrementFicheResult chiffrerFiche(Map<String, String> valeurs) {
    final details = <ChiffrementDetail>[];
    final parties = <String>[];
    final nomsChamps = getNomsChampsOrdonnes();

    for (final champ in nomsChamps) {
      final brut = valeurs[champ] ?? '';
      final result = chiffrerTexte(brut);
      details.add(
        ChiffrementDetail(
          champ: champ,
          brut: brut,
          crypto: result.crypto,
          ignores: result.ignores,
        ),
      );
      parties.add(result.crypto);

      final sep = _separateurPourChamp(champ);
      if (sep != null) {
        parties.add(sep.crypto);
        details.add(
          ChiffrementDetail(
            champ: '(sep après $champ)',
            brut: sep.separateur,
            crypto: sep.crypto,
            ignores: const [],
          ),
        );
      }
    }

    return ChiffrementFicheResult(
      resultat: parties.join(),
      details: details,
      chaineLogique: nomsChamps.map((champ) {
        final valeur = valeurs[champ] ?? '';
        final sep = _separateurPourChamp(champ);
        return valeur + (sep?.separateur ?? '');
      }).join(),
    );
  }

  static String? _ligneElementPourCrypto(String bloc) {
    if (bloc == 'nj39') {
      return ' ';
    }

    for (final item in _data.matriceElement) {
      if (item.crypto == bloc) {
        return item.element.isEmpty && item.crypto == 'nj39' ? ' ' : item.element;
      }
    }
    return null;
  }

  static String dechiffrerTexte(String crypto) {
    final valeur = crypto.toString();

    if (valeur.length % 4 != 0) {
      throw FormatException(
        'Le texte chiffré doit contenir des blocs de 4 caractères.',
      );
    }

    final texte = StringBuffer();
    for (var index = 0; index < valeur.length; index += 4) {
      final bloc = valeur.substring(index, index + 4);
      final element = _ligneElementPourCrypto(bloc);

      if (element == null) {
        throw FormatException('Le bloc « $bloc » est inconnu.');
      }

      texte.write(element);
    }

    return texte.toString();
  }

  static DechiffrementFicheResult dechiffrerFiche(String resultat) {
    final chaine = resultat.trim();
    final valeurs = <String, String>{};
    final details = <DechiffrementDetail>[];
    final nomsChamps = getNomsChampsOrdonnes();
    var debut = 0;

    for (final sep in _data.matriceSeparateur) {
      final position = chaine.indexOf(sep.crypto, debut);
      if (position == -1) {
        throw FormatException(
          'Le séparateur chiffré « ${sep.crypto} » est absent.',
        );
      }

      final champ = sep.champ;
      final crypto = chaine.substring(debut, position);
      final texte = dechiffrerTexte(crypto);
      valeurs[champ] = texte;
      details.add(
        DechiffrementDetail(
          champ: champ,
          crypto: crypto,
          texte: texte,
        ),
      );
      debut = position + sep.crypto.length;
    }

    final champsSansSeparateur = nomsChamps.where(
      (champ) => !_data.matriceSeparateur.any((sep) => sep.champ == champ),
    );

    if (champsSansSeparateur.isNotEmpty) {
      final dernierChamp = champsSansSeparateur.first;
      final dernierCrypto = chaine.substring(debut);
      final dernierTexte = dechiffrerTexte(dernierCrypto);
      valeurs[dernierChamp] = dernierTexte;
      details.add(
        DechiffrementDetail(
          champ: dernierChamp,
          crypto: dernierCrypto,
          texte: dernierTexte,
        ),
      );
    } else if (debut != chaine.length) {
      throw FormatException(
        'Des caractères restent après le dernier séparateur.',
      );
    }

    return DechiffrementFicheResult(
      valeurs: valeurs,
      details: details,
      chaineLogique: nomsChamps.map((champ) {
        MatriceSeparateur? sep;
        for (final item in _data.matriceSeparateur) {
          if (item.champ == champ) {
            sep = item;
            break;
          }
        }
        return '${valeurs[champ] ?? ''}${sep?.separateur ?? ''}';
      }).join(),
    );
  }
}
