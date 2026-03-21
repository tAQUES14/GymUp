import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

const _kBlue     = Color(0xFF2563EB);
const _kBlueDark = Color(0xFF1D4ED8);

class PersonalsPage extends StatelessWidget {
  const PersonalsPage({super.key});

  static const _personals = [
    (
      name: 'Ana Silva',
      specialty: 'Hipertrofia e Emagrecimento',
      description:
          'Especialista em transformação corporal com foco em saúde e bem-estar. 5 anos de experiência.',
    ),
    (
      name: 'João Pereira',
      specialty: 'Performance e Atletismo',
      description:
          'Treinamento voltado para atletas de alto rendimento e preparação física específica.',
    ),
    (
      name: 'Carlos Souza',
      specialty: 'Iniciantes e Reabilitação',
      description:
          'Foco em correção postural, fortalecimento e introdução à musculação.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _kBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Personais',
          style: AppTypography.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        itemCount: _personals.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) return _buildHeroHeader();
          final p = _personals[index - 1];
          return _buildPersonalCard(context, p.name, p.specialty, p.description);
        },
      ),
    );
  }

  // ── Hero header ───────────────────────────────────────────────────────────────

  Widget _buildHeroHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kBlue, _kBlueDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _kBlue.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.people_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nossa Equipe',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        )),
                    SizedBox(height: 4),
                    Text(
                      'Profissionais prontos para te ajudar a alcançar seus objetivos.',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Personal card ─────────────────────────────────────────────────────────────

  Widget _buildPersonalCard(
    BuildContext context,
    String name,
    String specialty,
    String description,
  ) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + nome + especialidade
            Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_kBlue, _kBlueDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B))),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(specialty,
                            style: const TextStyle(
                                color: _kBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Descrição
            Text(description,
                style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.5)),
            const SizedBox(height: 16),
            // CTA
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Funcionalidade de contato em breve!')),
                );
              },
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_kBlue, _kBlueDark]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('Quero saber mais',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
