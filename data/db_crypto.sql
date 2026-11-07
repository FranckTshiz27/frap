-- Matrice crypto FRAP — source SQL optimisée (hors APK)
-- Colonnes runtime uniquement, sans métadonnées d'audit.
-- Générer le JSON embarqué : dart run tool/generate_crypto_json.dart

CREATE TABLE IF NOT EXISTS t_dbdr_crypto_type_document (
  PK_TYPE_DOCUMENT INT UNSIGNED NOT NULL PRIMARY KEY,
  intitule VARCHAR(50) NOT NULL,
  init_separateur CHAR(1) NOT NULL
);

CREATE TABLE IF NOT EXISTS t_dbdr_crypto_matrice_element (
  FK_TYPE_DOCUMENT INT UNSIGNED NOT NULL,
  element CHAR(1) NOT NULL,
  crypto CHAR(4) NOT NULL,
  PRIMARY KEY (FK_TYPE_DOCUMENT, element),
  UNIQUE KEY uk_matrice_element_crypto (crypto)
);

CREATE TABLE IF NOT EXISTS t_dbdr_ordre_champs (
  FK_TYPE_DOCUMENT INT UNSIGNED NOT NULL,
  ordre INT NOT NULL,
  champs VARCHAR(20) NOT NULL,
  PRIMARY KEY (FK_TYPE_DOCUMENT, ordre)
);

CREATE TABLE IF NOT EXISTS t_dbdr_crypto_matrice_separateur (
  FK_TYPE_DOCUMENT INT UNSIGNED NOT NULL,
  champ VARCHAR(20) NOT NULL,
  separateur CHAR(1) NOT NULL,
  crypto CHAR(4) NOT NULL,
  PRIMARY KEY (FK_TYPE_DOCUMENT, champ),
  UNIQUE KEY uk_matrice_separateur_crypto (crypto)
);

INSERT INTO t_dbdr_crypto_type_document (PK_TYPE_DOCUMENT, intitule, init_separateur) VALUES
(1, 'F02', '#');

INSERT INTO t_dbdr_crypto_matrice_element (FK_TYPE_DOCUMENT, element, crypto) VALUES
(1, '0', 'uwmt'), (1, '1', 'kxnb'), (1, '2', 'bqfq'), (1, '3', 'hjtk'),
(1, '4', 'mosw'), (1, '5', 'rcpg'), (1, '6', 'ylnx'), (1, '7', 'zfdk'),
(1, '8', 'ystq'), (1, '9', 'utem'), (1, 'A', '1815'), (1, 'B', '9047'),
(1, 'C', '4516'), (1, 'D', '4090'), (1, 'E', '5603'), (1, 'F', '1294'),
(1, 'G', '8805'), (1, 'H', '5616'), (1, 'I', '4527'), (1, 'J', '1238'),
(1, 'K', '7849'), (1, 'L', '2090'), (1, 'M', '3921'), (1, 'N', '7572'),
(1, 'O', '1284'), (1, 'P', '4225'), (1, 'Q', '9505'), (1, 'R', '7416'),
(1, 'S', '4525'), (1, 'T', '2731'), (1, 'U', '1250'), (1, 'V', '9551'),
(1, 'W', '9462'), (1, 'X', '1574'), (1, 'Y', '2584'), (1, 'Z', '5496'),
(1, ' ', 'nj39'),
(1, 'À', '7843'), (1, 'Á', '0013'), (1, 'Â', '0913'), (1, 'Ã', '6651'),
(1, 'Ä', '0017'), (1, 'Å', '0914'), (1, 'Æ', '9651'), (1, 'Ç', '1100'),
(1, 'È', '5601'), (1, 'É', '7777'), (1, 'Ê', '1185'), (1, 'Ë', '8082'),
(1, 'Ì', '8002'), (1, 'Í', '4201'), (1, 'Î', '3001'), (1, 'Ï', '3360'),
(1, 'Ñ', '9001'), (1, 'Ò', '4196'), (1, 'Ó', '8912'), (1, 'Ô', '8602'),
(1, 'Õ', '2180'), (1, 'Ö', '1111'), (1, 'Œ', '1095'),
(1, 'Ù', '1205'), (1, 'Ú', '1210'), (1, 'Û', '1999'), (1, 'Ü', '1012'),
(1, 'Ý', '9165'), (1, 'Ÿ', '0110'),
(1, '''', '9931'), (1, ''', '4509'), (1, '-', '7090'), (1, '.', '1019');

INSERT INTO t_dbdr_ordre_champs (FK_TYPE_DOCUMENT, ordre, champs) VALUES
(1, 1, 'type'), (1, 2, 'nom'), (1, 3, 'postnom'), (1, 4, 'prénom'),
(1, 5, 'sexe'), (1, 6, 'date naissance'), (1, 7, 'matricule'), (1, 8, 'grade'),
(1, 9, 'fonction'), (1, 10, 'administration'), (1, 11, 'province'),
(1, 12, 'numéro fiche'), (1, 13, 'date émission fiche');

INSERT INTO t_dbdr_crypto_matrice_separateur (FK_TYPE_DOCUMENT, champ, separateur, crypto) VALUES
(1, 'type', '#', 'hf08'), (1, 'nom', '@', 'xt9m'), (1, 'postnom', '@', '8en1'),
(1, 'prénom', '@', 'o6v5'), (1, 'sexe', '@', 'yrt1'), (1, 'date naissance', '@', 'erc8'),
(1, 'matricule', '@', 'tf8h'), (1, 'grade', '@', 'i7k5'), (1, 'fonction', '@', 'l8i7'),
(1, 'administration', '@', '5j7q'), (1, 'province', '@', 'o9p6'),
(1, 'numéro fiche', '@', 'd2f9'), (1, 'date émission fiche', '@', '97j4');
