import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/agendamento.dart';
import '../utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseService();
  List<Agendamento> _proximosAgendamentos = [];
  int _totalSaloes = 0;
  int _totalAgendamentos = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final saloes = await _db.getSaloes();
    final agendamentos = await _db.getAgendamentos();
    final hoje = DateTime.now();
    final proximos = agendamentos
        .where(
          (a) =>
              a.dataEvento.isAfter(hoje.subtract(const Duration(days: 1))) &&
              a.status != 'cancelado',
        )
        .take(5)
        .toList();

    setState(() {
      _totalSaloes = saloes.length;
      _totalAgendamentos = agendamentos.length;
      _proximosAgendamentos = proximos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('🎉 Salões de Festa'),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.surfaceLight, AppTheme.surface],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: 10,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary.withOpacity(0.05),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Stats cards
                  Row(
                    children: [
                      _StatCard(
                        icon: Icons.celebration_rounded,
                        label: 'Salões',
                        value: '$_totalSaloes',
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.event_available_rounded,
                        label: 'Agendamentos',
                        value: '$_totalAgendamentos',
                        color: AppTheme.success,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        icon: Icons.today_rounded,
                        label: 'Este Mês',
                        value: '${_proximosAgendamentos.length}',
                        color: AppTheme.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Próximos eventos
                  const Text(
                    'Próximos Eventos',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_proximosAgendamentos.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.event_busy,
                            color: AppTheme.textSecondary,
                            size: 48,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Nenhum agendamento próximo',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._proximosAgendamentos.map(
                      (a) => _AgendamentoCard(agendamento: a),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendamentoCard extends StatelessWidget {
  final Agendamento agendamento;

  const _AgendamentoCard({required this.agendamento});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: agendamento.status.statusColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: agendamento.status.statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.event, color: agendamento.status.statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agendamento.nomeCliente,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${fmt.format(agendamento.dataEvento)} • ${agendamento.horaInicio.format()} - ${agendamento.horaFim.format()}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: agendamento.status.statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              agendamento.status.statusLabel,
              style: TextStyle(
                color: agendamento.status.statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
