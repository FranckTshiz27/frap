import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_fp/crypto/crypto_matrice_service.dart';
import 'package:mobile_fp/theme/app_colors.dart';
import 'package:mobile_fp/theme/app_typography.dart';

TextStyle _resultText({
  double fontSize = 15,
  Color? color,
}) {
  return AppTypography.feature.copyWith(
    fontSize: fontSize,
    fontWeight: FontWeight.w400,
    color: color,
  );
}

TextStyle _decryptedValueStyle({double fontSize = 13, Color? color}) {
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: FontWeight.w400,
    color: color ?? Colors.white,
    height: 1.35,
  );
}

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({
    super.key,
    required this.resultat,
  });

  final DechiffrementFicheResult resultat;

  String _valeur(String champ) {
    final value = resultat.valeurs[champ];
    if (value == null || value.isEmpty) {
      return '—';
    }
    return value;
  }

  static String _formatDate(String value) {
    final cleaned = value.replaceAll('/', '').replaceAll('-', '').trim();
    if (cleaned.length == 8 && int.tryParse(cleaned) != null) {
      return '${cleaned.substring(0, 2)}/'
          '${cleaned.substring(2, 4)}/'
          '${cleaned.substring(4)}';
    }
    return value;
  }

  static String _formatSexe(String value) {
    switch (value.toUpperCase()) {
      case 'M':
        return 'Masculin';
      case 'F':
        return 'Féminin';
      default:
        return value;
    }
  }

  static String _initials(String prenom, String nom) {
    final first = prenom.trim().isNotEmpty ? prenom.trim()[0].toUpperCase() : '';
    final last = nom.trim().isNotEmpty ? nom.trim()[0].toUpperCase() : '';
    return '$first$last';
  }

  static String _fullName(String prenom, String postnom, String nom) {
    return [prenom, postnom, nom].where((part) => part.trim().isNotEmpty).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final prenom = _valeur('prénom');
    final postnom = _valeur('postnom');
    final nom = _valeur('nom');
    final grade = _valeur('grade');
    final matricule = _valeur('matricule');

    return Scaffold(
      backgroundColor: AppColors.backgroundDeep,
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _ResultHeader(onBack: () => Navigator.of(context).pop()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ProfileSummaryCard(
                    initials: _initials(prenom, nom),
                    fullName: _fullName(prenom, postnom, nom),
                    grade: grade,
                    matricule: matricule,
                  ),
                  const SizedBox(height: 24),
                  _InfoSection(
                    title: 'INFORMATIONS PERSONNELLES',
                    rows: [
                      _InfoRow(label: 'Nom', value: nom),
                      _InfoRow(label: 'Postnom', value: postnom),
                      _InfoRow(label: 'Prénom', value: prenom),
                      _InfoRow(
                        label: 'Sexe',
                        value: _formatSexe(_valeur('sexe')),
                      ),
                      _InfoRow(
                        label: 'Date de naissance',
                        value: _formatDate(_valeur('date naissance')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _InfoSection(
                    title: 'INFORMATIONS PROFESSIONNELLES',
                    rows: [
                      _InfoRow(label: 'Matricule', value: matricule),
                      _InfoRow(label: 'Grade', value: grade),
                      _InfoRow(
                        label: 'Fonction',
                        value: _valeur('fonction'),
                      ),
                      _InfoRow(
                        label: 'Administration',
                        value: _valeur('administration'),
                      ),
                      _InfoRow(
                        label: 'Province',
                        value: _valeur('province'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _InfoSection(
                    title: 'INFORMATIONS DE LA FICHE',
                    rows: [
                      _InfoRow(
                        label: 'Numéro de fiche',
                        value: _valeur('numéro fiche'),
                      ),
                      _InfoRow(
                        label: 'Date d\'émission',
                        value: _formatDate(_valeur('date émission fiche')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _NouveauScanButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    const badge = _ValidBadge();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: AppColors.logoBackground,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onBack,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Données extraites',
                      style: _resultText(fontSize: 17),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cachet électronique scanné avec succès',
                      style: AppTypography.scanSubtitle.copyWith(fontSize: 13),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 10),
                    badge,
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValidBadge extends StatelessWidget {
  const _ValidBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.validBadgeBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.validBadgeBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.statusGreen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Valide',
            style: AppTypography.scanStatus.copyWith(
              color: AppColors.statusGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.initials,
    required this.fullName,
    required this.grade,
    required this.matricule,
  });

  final String initials;
  final String fullName;
  final String grade;
  final String matricule;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.resultCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: AppTypography.button.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    fullName,
                    style: _decryptedValueStyle(fontSize: 14),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    grade,
                    style: _decryptedValueStyle(
                      fontSize: 12,
                      color: AppColors.accent.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    matricule,
                    style: _decryptedValueStyle(fontSize: 12),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              textAlign: TextAlign.left,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.resultCard,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                rows[i],
                if (i < rows.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                    indent: 16,
                    endIndent: 16,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTypography.scanSubtitle.copyWith(fontSize: 13);
    final valueStyle = _decryptedValueStyle(fontSize: 13);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: labelStyle,
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: valueStyle,
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

class _NouveauScanButton extends StatelessWidget {
  const _NouveauScanButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          'Nouveau scan',
          style: _resultText(fontSize: 15),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }
}
