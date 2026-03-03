import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/agendamento.dart';
import '../models/salao.dart';
import '../utils/app_theme.dart';
import 'agendamento_form_screen.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  final _db = DatabaseService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Agendamento>> _events = {};
  List<Agendamento> _selectedEvents = [];
  List<Salao> _saloes = [];
  String? _filtroSalaoId;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _load();
  }

  Future<void> _load() async {
    final saloes = await _db.getSaloes();
    final agendamentos = await _db.getAgendamentos();

    final filtrados = _filtroSalaoId == null
        ? agendamentos
        : agendamentos.where((a) => a.salaoId == _filtroSalaoId).toList();

    final Map<DateTime, List<Agendamento>> events = {};
    for (var a in filtrados) {
      final key = DateTime(
        a.dataEvento.year,
        a.dataEvento.month,
        a.dataEvento.day,
      );
      events.putIfAbsent(key, () => []).add(a);
    }

    setState(() {
      _saloes = saloes;
      _events = events;
      if (_selectedDay != null) {
        final key = DateTime(
          _selectedDay!.year,
          _selectedDay!.month,
          _selectedDay!.day,
        );
        _selectedEvents = events[key] ?? [];
      }
    });
  }

  List<Agendamento> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
      final key = DateTime(selected.year, selected.month, selected.day);
      _selectedEvents = _events[key] ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário'),
        actions: [
          PopupMenuButton<String?>(
            icon: Icon(
              Icons.filter_list,
              color: _filtroSalaoId != null ? AppTheme.primary : null,
            ),
            color: AppTheme.cardBg,
            onSelected: (val) {
              setState(() => _filtroSalaoId = val);
              _load();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: null,
                child: Text(
                  'Todos os salões',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
              ),
              ..._saloes.map(
                (s) => PopupMenuItem(
                  value: s.id,
                  child: Text(
                    s.nome,
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AgendamentoFormScreen(dataInicial: _selectedDay),
            ),
          );
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.surface,
            child: TableCalendar<Agendamento>(
              locale: 'pt_BR',
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _getEventsForDay,
              onDaySelected: _onDaySelected,
              onPageChanged: (focused) => _focusedDay = focused,
              calendarStyle: CalendarStyle(
                defaultTextStyle: const TextStyle(color: AppTheme.textPrimary),
                weekendTextStyle: const TextStyle(
                  color: AppTheme.textSecondary,
                ),
                outsideTextStyle: TextStyle(
                  color: AppTheme.textSecondary.withOpacity(0.4),
                ),
                todayDecoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                markerDecoration: const BoxDecoration(
                  color: AppTheme.warning,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
              ),
              headerStyle: const HeaderStyle(
                titleTextStyle: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                formatButtonVisible: false,
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: AppTheme.primary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: AppTheme.primary,
                ),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
                weekendStyle: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  _selectedDay != null
                      ? DateFormat(
                          'dd \'de\' MMMM',
                          'pt_BR',
                        ).format(_selectedDay!)
                      : 'Selecione um dia',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                if (_selectedEvents.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_selectedEvents.length}',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _selectedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          color: AppTheme.textSecondary.withOpacity(0.4),
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Nenhum agendamento neste dia',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                    itemCount: _selectedEvents.length,
                    itemBuilder: (_, i) {
                      final a = _selectedEvents[i];
                      return _AgendamentoTile(
                        agendamento: a,
                        salaoNome: _saloes
                            .firstWhere(
                              (s) => s.id == a.salaoId,
                              orElse: () => Salao(id: '', nome: 'N/A'),
                            )
                            .nome,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AgendamentoFormScreen(agendamento: a),
                            ),
                          );
                          _load();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AgendamentoTile extends StatelessWidget {
  final Agendamento agendamento;
  final String salaoNome;
  final VoidCallback onTap;

  const _AgendamentoTile({
    required this.agendamento,
    required this.salaoNome,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: agendamento.status.statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                agendamento.horaInicio.format(),
                style: TextStyle(
                  color: agendamento.status.statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                agendamento.horaFim.format(),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        title: Text(
          agendamento.nomeCliente,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              salaoNome,
              style: const TextStyle(color: AppTheme.primary, fontSize: 12),
            ),
            if (agendamento.tipoEvento.isNotEmpty)
              Text(
                agendamento.tipoEvento,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        trailing: Container(
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
      ),
    );
  }
}
