import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hibrido/core/theme/custom_colors.dart';
import 'package:hibrido/features/activity/data/activity_repository.dart';
import 'package:hibrido/features/activity/models/activity_data.dart';
import '../widgets/activity_card.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with WidgetsBindingObserver {
  final ActivityRepository _repository = ActivityRepository();
  late Future<List<ActivityData>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    // Carrega as atividades salvas quando a tela é iniciada.
    _loadActivities();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Recarrega as atividades quando o app volta para o primeiro plano,
    // garantindo que a lista esteja sempre atualizada.
    if (state == AppLifecycleState.resumed) {
      _loadActivities();
    }
  }

  /// Carrega ou recarrega a lista de atividades do repositório.
  void _loadActivities() {
    _activitiesFuture = _repository.getActivities();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Atividades',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.bold,
            color: CustomColors.textLight,
          ),
        ),
      ),
      // Usa um FutureBuilder para construir a UI com base no estado do carregamento das atividades.
      body: FutureBuilder<List<ActivityData>>(
        future: _activitiesFuture,
        builder: (context, snapshot) {
          // Mostra um indicador de progresso enquanto os dados estão carregando.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Mostra uma mensagem de erro se algo der errado.
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar atividades: ${snapshot.error}'),
            );
          }
          // Mostra uma mensagem se não houver atividades salvas.
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Não tem atividades',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lexend(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: CustomColors.textDark.withOpacity(0.5),
                  ),
                ),
              ),
            );
          }

          final activities = snapshot.data!;

          // Constrói a lista de atividades quando os dados estiverem prontos.
          // Adiciona o RefreshIndicator para permitir "puxar para atualizar".
          return RefreshIndicator(
            onRefresh: () async => _loadActivities(),
            child: ListView.separated(
              itemCount: activities.length,
              itemBuilder: (context, index) {
                // Para cada item na lista de dados, criamos um widget de card.
                return ActivityCard(
                  activityData: activities[index],
                  onDelete: _loadActivities, // Passa a função de recarregar
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 8),
            ),
          );
        },
      ),
    );
  }
}
