import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_fp/crypto/crypto_matrice_repository.dart';
import 'package:mobile_fp/crypto/crypto_matrice_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await CryptoMatriceRepository.load();
  });

  const valeurs = {
    'type': 'F02',
    'nom': 'KABONGO',
    'postnom': 'MULUMBA',
    'prénom': 'JEAN',
    'sexe': 'M',
    'date naissance': '01011990',
    'matricule': 'ABC123',
    'grade': 'A1',
    'fonction': 'INSPECTEUR',
    'administration': 'MINISTERE',
    'province': 'KINSHASA',
    'numéro fiche': '00045',
    'date émission fiche': '30092026',
  };

  test('chiffrement puis déchiffrement d une fiche F02', () {
    final chiffre = CryptoMatriceService.chiffrerFiche(valeurs);
    final dechiffre = CryptoMatriceService.dechiffrerFiche(chiffre.resultat);

    expect(dechiffre.valeurs, valeurs);
    expect(dechiffre.chaineLogique, chiffre.chaineLogique);
  });

  test('chiffrement et dechiffrement avec espaces', () {
    const texte = 'MEDECIN INTERNE';

    final chiffre = CryptoMatriceService.chiffrerTexte(texte);
    final dechiffre = CryptoMatriceService.dechiffrerTexte(chiffre.crypto);

    expect(chiffre.crypto, contains('nj39'));
    expect(dechiffre, texte);
    expect(chiffre.ignores, isEmpty);
  });

  test('matrice espace nj39 chargee correctement', () {
    final data = CryptoMatriceRepository.data;
    final espace = data.matriceElement.firstWhere((e) => e.crypto == 'nj39');

    expect(espace.element, ' ');
    expect(data.cryptoParElement[' '], 'nj39');
    expect(data.elementParCrypto['nj39'], ' ');
  });

  test('chiffrement fiche avec espace dans la fonction', () {
    final valeursAvecEspace = Map<String, String>.from(valeurs)
      ..['fonction'] = 'MEDECIN INTERNE';

    final chiffre = CryptoMatriceService.chiffrerFiche(valeursAvecEspace);
    final dechiffre = CryptoMatriceService.dechiffrerFiche(chiffre.resultat);

    expect(chiffre.details.firstWhere((d) => d.champ == 'fonction').crypto,
        contains('nj39'));
    expect(dechiffre.valeurs['fonction'], 'MEDECIN INTERNE');
  });

  test('dechiffrement d une fiche F02 encodee en Base64', () {
    const payloadBase64 =
        'MTI5NHV3bXRicWZxaGYwODc4NDkxODE1MjA5MDEyODQ3NTcyMTIzODQ1Mjd4dDlt'
        'MjczMTQ1MjU1NjE2NDUyNzIwOTAxMjg0MzkyMTkwNDcxODE1OGVuMTQ1MjUxODE1'
        'OTA0Nzc0MTY0NTI3NzU3MjE4MTVvNnY1MTI5NDU2MDMzOTIxNDUyNzc1NzI0NTI3'
        'NzU3MnlydDF1d210dXRlbXV3bXR5c3Rxa3huYnV0ZW15c3RxbW9zd2VyYzhreG5i'
        'cmNwZ2t4bmJ1dGVtaGp0a3lzdHF1dGVtdGY4aDM5MjE1NjAzNDA5MDU2MDM0NTE2'
        'NDUyNzc1NzI0NTI3NzU3MjI3MzE1NjAzNzQxNjc1NzI1NjAzaTdrNTM5MjE1NjAz'
        'NDA5MDU2MDM0NTE2NDUyNzc1NzI0NTI3NzU3MjI3MzE1NjAzNzQxNjc1NzI1NjAz'
        'bDhpNzQ1MjUxODE1NzU3MjI3MzE1NjAzNWo3cTc4NDk0NTI3NzU3MjQ1MjU1NjE2'
        'MTgxNTQ1MjUxODE1bzlwNmt4bmJkMmY5dXdtdHlzdHFreG5idXdtdGJxZnF1d210'
        'YnFmcXlsbng5N2o0';

    final dechiffre = CryptoMatriceService.dechiffrerFicheScan(payloadBase64);

    expect(dechiffre.valeurs['type'], 'F02');
    expect(dechiffre.valeurs['nom'], 'KALONJI');
    expect(dechiffre.valeurs['administration'], 'SANTE');
    expect(dechiffre.valeurs['province'], 'KINSHASA');
  });

  test('dechiffrement round trip Base64', () {
    final chiffre = CryptoMatriceService.chiffrerFiche(valeurs);
    final payloadBase64 = base64.encode(utf8.encode(chiffre.resultat));

    final dechiffre = CryptoMatriceService.dechiffrerFicheScan(payloadBase64);

    expect(dechiffre.valeurs, valeurs);
  });
}
