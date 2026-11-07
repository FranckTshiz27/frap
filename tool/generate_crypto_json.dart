import 'dart:convert';
import 'dart:io';

/// Génère assets/crypto/db_crypto.json à partir de data/db_crypto.sql
void main() {
  final sqlFile = File('data/db_crypto.sql');
  if (!sqlFile.existsSync()) {
    stderr.writeln('Fichier introuvable : data/db_crypto.sql');
    exit(1);
  }

  final sql = sqlFile.readAsStringSync();
  final json = _buildJsonFromSql(sql);
  final output = File('assets/crypto/db_crypto.json');
  output.parent.createSync(recursive: true);
  output.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(json));

  stdout.writeln('Généré : ${output.path} (${output.lengthSync()} octets)');
}

Map<String, Object> _buildJsonFromSql(String sql) {
  return {
    'version': 1,
    'typeDocument': _parseInserts(
      sql,
      't_dbdr_crypto_type_document',
      (row) => {
        'id': _int(row[0]),
        'intitule': row[1],
        'initSeparateur': row[2],
      },
    ),
    'matriceElement': _parseInserts(
      sql,
      't_dbdr_crypto_matrice_element',
      (row) => {
        'fk': _int(row[0]),
        'element': row[1],
        'crypto': row[2],
      },
    ),
    'ordreChamps': _parseInserts(
      sql,
      't_dbdr_ordre_champs',
      (row) => {
        'fk': _int(row[0]),
        'ordre': _int(row[1]),
        'champs': row[2],
      },
    ),
    'matriceSeparateur': _parseInserts(
      sql,
      't_dbdr_crypto_matrice_separateur',
      (row) => {
        'fk': _int(row[0]),
        'champ': row[1],
        'separateur': row[2],
        'crypto': row[3],
      },
    ),
  };
}

List<Map<String, Object>> _parseInserts(
  String sql,
  String table,
  Map<String, Object> Function(List<String> row) mapRow,
) {
  final pattern = RegExp(
    'INSERT INTO $table \\([^)]+\\) VALUES\\s*([\\s\\S]*?);',
    multiLine: true,
  );
  final match = pattern.firstMatch(sql);
  if (match == null) {
    throw StateError('INSERT introuvable pour $table');
  }

  final valuesBlock = match.group(1)!;
  final rows = <Map<String, Object>>[];

  for (final tuple in _splitTuples(valuesBlock)) {
    rows.add(mapRow(_parseTuple(tuple)));
  }

  return rows;
}

Iterable<String> _splitTuples(String block) sync* {
  final buffer = StringBuffer();
  var depth = 0;
  var inQuote = false;

  for (var i = 0; i < block.length; i++) {
    final char = block[i];
    if (char == "'" && (i == 0 || block[i - 1] != r'\')) {
      inQuote = !inQuote;
    }

    if (!inQuote) {
      if (char == '(') {
        depth++;
        if (depth == 1) {
          buffer.clear();
          continue;
        }
      } else if (char == ')') {
        depth--;
        if (depth == 0) {
          yield buffer.toString();
          buffer.clear();
          continue;
        }
      }
    }

    if (depth >= 1) {
      buffer.write(char);
    }
  }
}

List<String> _parseTuple(String tuple) {
  final values = <String>[];
  final buffer = StringBuffer();
  var inQuote = false;

  for (var i = 0; i < tuple.length; i++) {
    final char = tuple[i];
    if (char == "'" && (i == 0 || tuple[i - 1] != r'\')) {
      inQuote = !inQuote;
      continue;
    }

    if (char == ',' && !inQuote) {
      values.add(buffer.toString());
      buffer.clear();
      continue;
    }

    buffer.write(char);
  }

  if (buffer.isNotEmpty) {
    values.add(buffer.toString());
  }

  return values;
}

int _int(String value) => int.parse(value.trim());
