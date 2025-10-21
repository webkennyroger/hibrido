import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/features/activity/data/activity_repository.dart';
import 'package:hibrido/core/theme/custom_colors.dart';

import 'package:hibrido/features/settings/screens/account_settings_screen.dart';
import 'package:hibrido/features/settings/screens/notifications_screen.dart';
import 'package:hibrido/providers/user_provider.dart';
import 'package:provider/provider.dart';

// O enum para a aba selecionada
enum TimePeriod { semana, mes, ano }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final ActivityRepository _repository = ActivityRepository();
  bool _isLoading = true;
  int _activitiesCount = 0;
  double _totalDistanceKm = 0.0;
  double _totalHours = 0.0;
  int _totalPoints = 0;
  List<double> _weeklyDistances = List.filled(7, 0.0);

  // Estado para o período selecionado (Semana, Mês, Ano)
  TimePeriod _selectedPeriod = TimePeriod.semana;
  // Mock para a atividade selecionada no dropdown
  String _selectedActivity = 'Todas as Atividades';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final stats = await _repository.calculateAggregatedStats();

    if (mounted) {
      setState(() {
        _activitiesCount = stats.activityCount;
        _totalDistanceKm = stats.totalDistanceKm;
        _totalHours = stats.totalHours;
        _totalPoints = stats.totalPoints;
        _weeklyDistances = stats.weeklyDistances;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definimos as cores. Assumindo que o tema é escuro.
    final colors = AppColors.of(context);
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      backgroundColor: colors.background,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Cabeçalho Personalizado (Voltar, Título, Ações)
                _buildCustomHeader(context, colors),

                const SizedBox(height: 10),

                // 2. Linha Divisória
                Divider(
                  color: colors.surface,
                  thickness: 1.0,
                  indent: 20,
                  endIndent: 20,
                ),

                // 3. Informações do Usuário e Conquistas
                _buildUserStatusSection(context, colors, user),

                const SizedBox(height: 30),

                // 4. Gráfico Semi-Circular (Radial) com valor dinâmico
                _buildRadialChartSection(colors, _totalPoints),

                const SizedBox(height: 30),

                // 5. Estatísticas Chave (Dinâmicas)
                _buildKeyStatsCard(
                  colors,
                  _activitiesCount,
                  _totalHours,
                  _totalDistanceKm,
                ),

                const SizedBox(height: 30),

                // 6. Divisor no lugar da barra de progresso
                const Divider(indent: 20, endIndent: 20),

                const SizedBox(height: 30),

                // 7. Tabs de Período (Semana, Mês, Ano)
                _buildPeriodTabs(colors),

                // 8. Seção de Tendência (Título + Dropdown)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _buildTrendHeader(colors),
                ),

                const SizedBox(height: 15),

                // 9. Gráfico de 7 Dias Anteriores (Dinâmico)
                _buildSevenDayChartMock(colors, _weeklyDistances),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGETS DE COMPOSIÇÃO DA TELA ---

  // 1. Cabeçalho Customizado
  Widget _buildCustomHeader(BuildContext context, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botão de Voltar
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: colors.text, size: 24),
            onPressed: () => Navigator.of(context).pop(),
          ),

          // Título da Tela
          Text(
            'Estatísticas',
            style: GoogleFonts.lexend(
              color: colors.text,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Ícones de Ação (Notificação e Configurações)
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_none,
                  color: colors.text,
                  size: 28,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: colors.text,
                  size: 28,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Informações do Usuário e Conquistas
  Widget _buildUserStatusSection(
    BuildContext context,
    AppColors colors,
    dynamic user,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Informações do Usuário (igual da Home)
          Row(
            children: [
              CircleAvatar(backgroundImage: user.profileImage, radius: 20),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: GoogleFonts.lexend(
                      color: colors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    user.location,
                    style: GoogleFonts.lexend(
                      color: colors.text.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Item de Fogo/Conquista
          _buildStatusItem(
            icon: Icons.local_fire_department,
            label: 'Conquistas',
            colors: colors,
            iconColor: AppColors.error, // Vermelho/Laranja para Fogo/Conquista
          ),
        ],
      ),
    );
  }

  // Item Auxiliar para Status (Câmera, Fogo)
  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required AppColors colors,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: GoogleFonts.lexend(color: colors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  // 4. Gráfico Semi-Circular (Radial)
  Widget _buildRadialChartSection(AppColors colors, int totalPoints) {
    // Usando um CustomPaint para simular o gráfico circular.
    // O valor 100% será simulado.
    const double size = 180;
    const double strokeWidth = 15;
    final double percentage = (totalPoints / 200).clamp(
      0.0,
      1.0,
    ); // Meta de 200 pontos

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Círculo de Fundo (Simula o "círculo cinza")
            CustomPaint(
              size: const Size.square(size),
              painter: _RadialChartPainter(
                percentage: 1.0, // Fundo é 100%
                color: colors.surface, // Cor de fundo do gráfico
                strokeWidth: strokeWidth,
                isFullCircle: true,
              ),
            ),
            // Círculo de Progresso (Simula o "círculo verde-limão")
            CustomPaint(
              size: const Size.square(size),
              painter: _RadialChartPainter(
                percentage: percentage,
                color: AppColors.primary, // Cor de progresso
                strokeWidth: strokeWidth,
                isFullCircle: false,
              ),
            ),
            // Valor Central
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        totalPoints.toString(),
                        style: GoogleFonts.lexend(
                          color: colors.text,
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                Text(
                  'PTS',
                  style: GoogleFonts.lexend(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 5. Estatísticas Chave (Atividades, Horas, KM) - Ajustado para o layout da imagem
  Widget _buildKeyStatsCard(
    AppColors colors,
    int activityCount,
    double totalHours,
    double totalDistance,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(15),
        ),
        child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildStatItem(
                        activityCount.toString(),
                        'Atividades',
                        colors,
                      ),
              ),
              VerticalDivider(
                color: colors.text.withOpacity(0.12),
                thickness: 1,
                indent: 10,
                endIndent: 10,
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildStatItem(
                        '${totalHours.toStringAsFixed(1)}h',
                        'Horas',
                        colors,
                      ),
              ),
              VerticalDivider(
                color: colors.text.withOpacity(0.12),
                thickness: 1,
                indent: 10,
                endIndent: 10,
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildStatItem(
                        totalDistance.toStringAsFixed(1),
                        'KM',
                        colors,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Item de estatística (estilo da tela de perfil)
  Widget _buildStatItem(String value, String label, AppColors colors) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.lexend(
            color: AppColors.primary, // Cor Primária (Verde) para o valor
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.lexend(
            color: colors.textSecondary, // Cinza sutil
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // 7. Tabs de Período (Semana, Mês, Ano)
  Widget _buildPeriodTabs(AppColors colors) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min, // Para centralizar o conteúdo da Row
        children: TimePeriod.values.map((period) {
          final isSelected = _selectedPeriod == period;
          String text = period.toString().split('.').last;
          text = text[0].toUpperCase() + text.substring(1); // Capitalize

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPeriod = period;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : colors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                text,
                style: GoogleFonts.lexend(
                  color: isSelected ? colors.surface : colors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 8. Seção de Tendência (Título + Dropdown de Atividades)
  Widget _buildTrendHeader(AppColors colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Título
        Expanded(
          child: Text(
            'Distância Média (6 semanas): 10.21 km', // Mock do texto
            style: GoogleFonts.lexend(
              color: colors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Dropdown de Atividades (Select)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedActivity,
              dropdownColor: colors.surface,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: colors.textSecondary,
              ),
              style: GoogleFonts.lexend(color: colors.text, fontSize: 14),
              items:
                  <String>[
                    'Todas as Atividades',
                    'Corrida',
                    'Pedalada',
                    'Caminhada',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedActivity = newValue!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // 9. Gráfico de 7 Dias Anteriores (Mockup)
  Widget _buildSevenDayChartMock(AppColors colors, List<double> distances) {
    final List<String> days = _repository.getLast7DaysAbbreviated();
    // Encontra a distância máxima para escalar o gráfico, com um mínimo de 5km.
    final double maxDistance = (distances.reduce((a, b) => a > b ? a : b) * 1.2)
        .clamp(5, double.infinity);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 180,
      padding: const EdgeInsets.only(top: 10, bottom: 0, left: 10, right: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Área de Rótulos Y (Vertical) - Mockup
                Row(
                  children: [
                    // Simulação de Rótulos Y (eixo vertical)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(4, (index) {
                        final value = maxDistance * (1 - index / 3);
                        return Padding(
                          padding: const EdgeInsets.only(right: 5, bottom: 20),
                          child: Text(
                            '${value.toStringAsFixed(1)}km',
                            style: GoogleFonts.lexend(
                              color: colors.textSecondary.withOpacity(0.5),
                              fontSize: 10,
                            ),
                          ),
                        );
                      }),
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 120, // Altura para o gráfico
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          // Onde o gráfico de linha ou barras iria
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(7, (index) {
                              // Simulação de Barras para simplificar o mockup
                              final heightFactor =
                                  (distances[index] / maxDistance).clamp(
                                    0.0,
                                    1.0,
                                  );
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    width: 15,
                                    height:
                                        heightFactor * 100, // Altura em pixels
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                // Rótulos X (Horizontal - Dias)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: days
                      .map(
                        (day) => Text(
                          day,
                          style: GoogleFonts.lexend(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
    );
  }
}

// --- WIDGET PARA DESENHO DO GRÁFICO RADIAL ---

/// CustomPainter para desenhar o gráfico semi-circular de progresso.
class _RadialChartPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final double strokeWidth;
  final bool isFullCircle; // Para desenhar o círculo de fundo

  _RadialChartPainter({
    required this.percentage,
    required this.color,
    required this.strokeWidth,
    this.isFullCircle = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;

    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap
          .round // Bordas arredondadas
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    if (isFullCircle) {
      // Desenha o círculo de fundo completo
      canvas.drawCircle(center, radius, paint);
    } else {
      // Desenha o arco de progresso
      const startAngle =
          -90.0 * (3.14159265359 / 180.0); // Começa no topo (12 horas)
      final sweepAngle = 360 * percentage * (3.14159265359 / 180.0);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false, // Não conecta ao centro (apenas linha de arco)
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadialChartPainter oldDelegate) {
    // Repinta apenas se a porcentagem ou a cor mudarem
    return oldDelegate.percentage != percentage || oldDelegate.color != color;
  }
}
