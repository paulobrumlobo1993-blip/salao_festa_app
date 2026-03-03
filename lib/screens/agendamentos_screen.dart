import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/agendamento.dart';
import '../models/salao.dart';
import '../utils/app_theme.dart';
import 'agendamento_form_screen.dart';

class AgendamentosScreen extends StatefulWidget {
  const AgendamentosScreen({super.key});

  @override
  State<AgendamentosScreen> createState() => _AgendamentosScreenState();
}

class _AgendamentosScreenState extends State<AgendamentosScreen> {
  final _db = DatabaseService();
  List<Agendamento> _agendamentos = [];
  List<Salao> _saloes = [];
  String _filtroStatus = 'todos';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final [saloes, agendamentos] = await Future.wait([
      _db.getSaloes(),
      _db.getAgendamentos(),
    ]);
    setState(() {
      _saloes = saloes as List<Salao>;
      _agendamentos = agendamentos as List<Agendamento>;
      _loading = false;
    });
  }

  List<Agendamento> get _filtrados {
    if (_filtroStatus == 'todos') return _agendamentos;
    return _agendamentos.where((a) => a.status == _filtroStatus).toList();
  }

  Future<void> _delete(Agendamento a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text(
          'Excluir Agendamento',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Excluir agendamento de "${a.nomeCliente}"?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.deleteAgendamento(a.id);
      _load();
    }
  }

  Future<void> _changeStatus(Agendamento a, String status) async {
    a.status = status;
    await _db.updateAgendamento(a);
    _load();
  }

  String _getSalaoNome(String salaoId) {
    return _saloes
        .firstWhere(
          (s) => s.id == salaoId,
          orElse: () => Salao(id: '', nome: 'N/A'),
        )
        .nome;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agendamentos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AgendamentoFormScreen()),
          );
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo Agendamento'),
      ),
      body: Column(
        children: [
          // Filtro de status
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['todos', 'pendente', 'confirmado', 'cancelado'].map((
                  s,
                ) {
                  final isSelected = _filtroStatus == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(s == 'todos' ? 'Todos' : s.statusLabel),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _filtroStatus = s),
                      backgroundColor: AppTheme.cardBg,
                      selectedColor: AppTheme.primary.withOpacity(0.2),
                      checkmarkColor: AppTheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.primary
                            : Colors.transparent,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : _filtrados.isEmpty
                ? _EmptyState(
                    status: _filtroStatus,
                    onAdd: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AgendamentoFormScreen(),
                        ),
                      );
                      _load();
                    },
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppTheme.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _filtrados.length,
                      itemBuilder: (_, i) {
                        final a = _filtrados[i];
                        return _AgendamentoCard(
                          agendamento: a,
                          salaoNome: _getSalaoNome(a.salaoId),
                          onEdit: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AgendamentoFormScreen(agendamento: a),
                              ),
                            );
                            _load();
                          },
                          onDelete: () => _delete(a),
                          onChangeStatus: (status) => _changeStatus(a, status),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AgendamentoCard extends StatelessWidget {
  final Agendamento agendamento;
  final String salaoNome;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(String) onChangeStatus;

  const _AgendamentoCard({
    required this.agendamento,
    required this.salaoNome,
    required this.onEdit,
    required this.onDelete,
    required this.onChangeStatus,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final statusColor = agendamento.status.statusColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agendamento.nomeCliente,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        salaoNome,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppTheme.textSecondary,
                  ),
                  color: AppTheme.cardBg,
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                    if (val == 'confirmado' ||
                        val == 'pendente' ||
                        val == 'cancelado') {
                      onChangeStatus(val);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: AppTheme.primary, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Editar',
                            style: TextStyle(color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'confirmado',
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppTheme.success,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Confirmar',
                            style: TextStyle(color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'pendente',
                      child: Row(
                        children: [
                          Icon(
                            Icons.pending,
                            color: AppTheme.warning,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Pendente',
                            style: TextStyle(color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'cancelado',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: AppTheme.danger, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Cancelar',
                            style: TextStyle(color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppTheme.danger, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Excluir',
                            style: TextStyle(color: AppTheme.danger),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _InfoBadge(
                  icon: Icons.calendar_today,
                  label: fmt.format(agendamento.dataEvento),
                ),
                _InfoBadge(
                  icon: Icons.access_time,
                  label:
                      '${agendamento.horaInicio.format()} - ${agendamento.horaFim.format()}',
                ),
                if (agendamento.numeroPessoas > 0)
                  _InfoBadge(
                    icon: Icons.people,
                    label: '${agendamento.numeroPessoas} pessoas',
                  ),
                if (agendamento.valorTotal > 0)
                  _InfoBadge(
                    icon: Icons.attach_money,
                    label: 'R\$ ${agendamento.valorTotal.toStringAsFixed(2)}',
                  ),
              ],
            ),
            if (agendamento.tipoEvento.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '🎉 ${agendamento.tipoEvento}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                agendamento.status.statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primary, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String status;
  final VoidCallback onAdd;

  const _EmptyState({required this.status, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            color: AppTheme.textSecondary.withOpacity(0.4),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            status == 'todos'
                ? 'Nenhum agendamento'
                : 'Nenhum agendamento ${status.statusLabel.toLowerCase()}',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crie um novo agendamento',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Novo Agendamento'),
          ),
        ],
      ),
    );
  }
}
