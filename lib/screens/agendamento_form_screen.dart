import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/agendamento.dart';
import '../models/salao.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';

class AgendamentoFormScreen extends StatefulWidget {
  final Agendamento? agendamento;
  final DateTime? dataInicial;

  const AgendamentoFormScreen({super.key, this.agendamento, this.dataInicial});

  @override
  State<AgendamentoFormScreen> createState() => _AgendamentoFormScreenState();
}

class _AgendamentoFormScreenState extends State<AgendamentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();
  List<Salao> _saloes = [];
  bool _loading = true;
  bool _saving = false;

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _telCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _tipoCtrl;
  late final TextEditingController _pessoasCtrl;
  late final TextEditingController _valorCtrl;
  late final TextEditingController _obsCtrl;

  String? _salaoId;
  DateTime _dataEvento = DateTime.now();
  TimeOfDay _horaInicio = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _horaFim = const TimeOfDay(hour: 14, minute: 0);
  String _status = 'pendente';

  @override
  void initState() {
    super.initState();
    final a = widget.agendamento;
    _nomeCtrl = TextEditingController(text: a?.nomeCliente ?? '');
    _telCtrl = TextEditingController(text: a?.telefoneCliente ?? '');
    _emailCtrl = TextEditingController(text: a?.email ?? '');
    _tipoCtrl = TextEditingController(text: a?.tipoEvento ?? '');
    _pessoasCtrl = TextEditingController(
      text: a != null && a.numeroPessoas > 0 ? '${a.numeroPessoas}' : '',
    );
    _valorCtrl = TextEditingController(
      text: a != null && a.valorTotal > 0 ? '${a.valorTotal}' : '',
    );
    _obsCtrl = TextEditingController(text: a?.observacoes ?? '');

    if (a != null) {
      _salaoId = a.salaoId;
      _dataEvento = a.dataEvento;
      _horaInicio = TimeOfDay(
        hour: a.horaInicio.hour,
        minute: a.horaInicio.minute,
      );
      _horaFim = TimeOfDay(hour: a.horaFim.hour, minute: a.horaFim.minute);
      _status = a.status;
    } else if (widget.dataInicial != null) {
      _dataEvento = widget.dataInicial!;
    }

    _loadSaloes();
  }

  Future<void> _loadSaloes() async {
    _saloes = await _db.getSaloes();
    if (_salaoId == null && _saloes.isNotEmpty) {
      _salaoId = _saloes.first.id;
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    _tipoCtrl.dispose();
    _pessoasCtrl.dispose();
    _valorCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataEvento,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary,
            onPrimary: Colors.black,
            surface: AppTheme.cardBg,
            onSurface: AppTheme.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dataEvento = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _horaInicio : _horaFim;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary,
            onPrimary: Colors.black,
            surface: AppTheme.cardBg,
            onSurface: AppTheme.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart)
          _horaInicio = picked;
        else
          _horaFim = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_salaoId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione um salão')));
      return;
    }

    setState(() => _saving = true);
    try {
      final agendamento =
          widget.agendamento ??
          Agendamento(
            id: const Uuid().v4(),
            salaoId: _salaoId!,
            nomeCliente: _nomeCtrl.text.trim(),
            dataEvento: _dataEvento,
            horaInicio: TimeOfDayData(
              hour: _horaInicio.hour,
              minute: _horaInicio.minute,
            ),
            horaFim: TimeOfDayData(
              hour: _horaFim.hour,
              minute: _horaFim.minute,
            ),
          );

      agendamento
        ..salaoId = _salaoId!
        ..nomeCliente = _nomeCtrl.text.trim()
        ..telefoneCliente = _telCtrl.text.trim()
        ..email = _emailCtrl.text.trim()
        ..dataEvento = _dataEvento
        ..horaInicio = TimeOfDayData(
          hour: _horaInicio.hour,
          minute: _horaInicio.minute,
        )
        ..horaFim = TimeOfDayData(hour: _horaFim.hour, minute: _horaFim.minute)
        ..tipoEvento = _tipoCtrl.text.trim()
        ..numeroPessoas = int.tryParse(_pessoasCtrl.text) ?? 0
        ..valorTotal = double.tryParse(_valorCtrl.text) ?? 0
        ..status = _status
        ..observacoes = _obsCtrl.text.trim();

      if (widget.agendamento == null) {
        await _db.insertAgendamento(agendamento);
      } else {
        await _db.updateAgendamento(agendamento);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.agendamento == null
                  ? 'Agendamento criado com sucesso!'
                  : 'Agendamento atualizado!',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.agendamento != null;
    final fmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar Agendamento' : 'Novo Agendamento'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _saloes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.celebration,
                    color: AppTheme.textSecondary,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Cadastre um salão primeiro',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'É necessário ter um salão cadastrado para agendar.',
                    style: TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Voltar'),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Salão
                  _SectionTitle(title: 'Salão'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _salaoId,
                        dropdownColor: AppTheme.cardBg,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        icon: const Icon(
                          Icons.expand_more,
                          color: AppTheme.primary,
                        ),
                        items: _saloes
                            .map(
                              (s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.nome),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _salaoId = v),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Data e hora
                  _SectionTitle(title: 'Data e Hora'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _PickerTile(
                          icon: Icons.calendar_today,
                          label: 'Data',
                          value: fmt.format(_dataEvento),
                          onTap: _pickDate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _PickerTile(
                          icon: Icons.access_time,
                          label: 'Início',
                          value: _horaInicio.format(context),
                          onTap: () => _pickTime(true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PickerTile(
                          icon: Icons.access_time_filled,
                          label: 'Término',
                          value: _horaFim.format(context),
                          onTap: () => _pickTime(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Cliente
                  _SectionTitle(title: 'Dados do Cliente'),
                  const SizedBox(height: 8),
                  _field(
                    _nomeCtrl,
                    'Nome do Cliente *',
                    Icons.person,
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _telCtrl,
                    'Telefone',
                    Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _emailCtrl,
                    'E-mail',
                    Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  // Evento
                  _SectionTitle(title: 'Detalhes do Evento'),
                  const SizedBox(height: 8),
                  _field(
                    _tipoCtrl,
                    'Tipo de Evento (ex: Casamento)',
                    Icons.celebration,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          _pessoasCtrl,
                          'Nº Pessoas',
                          Icons.people,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          _valorCtrl,
                          'Valor Total (R\$)',
                          Icons.attach_money,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _field(_obsCtrl, 'Observações', Icons.notes, maxLines: 3),
                  const SizedBox(height: 20),

                  // Status
                  _SectionTitle(title: 'Status'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['pendente', 'confirmado', 'cancelado'].map((s) {
                      final isSelected = _status == s;
                      return ChoiceChip(
                        label: Text(s.statusLabel),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _status = s),
                        selectedColor: s.statusColor.withOpacity(0.2),
                        backgroundColor: AppTheme.cardBg,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? s.statusColor
                              : AppTheme.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? s.statusColor
                              : Colors.transparent,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              isEdit
                                  ? 'Salvar Alterações'
                                  : 'Criar Agendamento',
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: required
          ? (v) => v!.trim().isEmpty ? 'Campo obrigatório' : null
          : null,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 18),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
