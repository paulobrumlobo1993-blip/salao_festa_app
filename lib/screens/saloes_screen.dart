import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/salao.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';
import 'salao_detail_screen.dart';

class SaloesScreen extends StatefulWidget {
  const SaloesScreen({super.key});

  @override
  State<SaloesScreen> createState() => _SaloesScreenState();
}

class _SaloesScreenState extends State<SaloesScreen> {
  final _db = DatabaseService();
  List<Salao> _saloes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _saloes = await _db.getSaloes();
    setState(() => _loading = false);
  }

  void _openForm([Salao? salao]) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SalaoFormSheet(salao: salao),
    );
    if (result == true) _load();
  }

  Future<void> _deleteSalao(Salao salao) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text(
          'Excluir Salão',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Deseja excluir "${salao.nome}"? Todos os agendamentos também serão removidos.',
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
      await _db.deleteSalao(salao.id);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${salao.nome} excluído')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Salões de Festa')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Novo Salão'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _saloes.isEmpty
          ? _EmptyState(onAdd: () => _openForm())
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primary,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _saloes.length,
                itemBuilder: (_, i) => _SalaoCard(
                  salao: _saloes[i],
                  onEdit: () => _openForm(_saloes[i]),
                  onDelete: () => _deleteSalao(_saloes[i]),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SalaoDetailScreen(salao: _saloes[i]),
                      ),
                    );
                    _load();
                  },
                ),
              ),
            ),
    );
  }
}

class _SalaoCard extends StatelessWidget {
  final Salao salao;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _SalaoCard({
    required this.salao,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto cover
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: salao.fotos.isNotEmpty
                  ? Image.file(
                      File(salao.fotos.first),
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _PhotoPlaceholder(),
                    )
                  : _PhotoPlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          salao.nome,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      PopupMenuButton(
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppTheme.textSecondary,
                        ),
                        color: AppTheme.cardBg,
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            onTap: onEdit,
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  color: AppTheme.primary,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Editar',
                                  style: TextStyle(color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            onTap: onDelete,
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  color: AppTheme.danger,
                                  size: 18,
                                ),
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
                  if (salao.endereco.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppTheme.textSecondary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            salao.endereco,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.people,
                        label: '${salao.capacidade.toInt()} pessoas',
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.attach_money,
                        label: 'R\$ ${salao.precoPorHora.toStringAsFixed(0)}/h',
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.category,
                        label: '${salao.itens.length} itens',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      color: AppTheme.surfaceLight,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.celebration, color: AppTheme.primary, size: 40),
          SizedBox(height: 4),
          Text(
            'Sem foto',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

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
          Icon(icon, color: AppTheme.primary, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.celebration,
              color: AppTheme.primary,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nenhum salão cadastrado',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adicione seu primeiro salão de festa',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Salão'),
          ),
        ],
      ),
    );
  }
}

// ─── FORM SHEET ──────────────────────────────────────────────────────────────
class SalaoFormSheet extends StatefulWidget {
  final Salao? salao;

  const SalaoFormSheet({super.key, this.salao});

  @override
  State<SalaoFormSheet> createState() => _SalaoFormSheetState();
}

class _SalaoFormSheetState extends State<SalaoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();
  final _picker = ImagePicker();
  bool _saving = false;

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _endCtrl;
  late final TextEditingController _telCtrl;
  late final TextEditingController _capCtrl;
  late final TextEditingController _precoCtrl;

  List<String> _fotos = [];

  @override
  void initState() {
    super.initState();
    final s = widget.salao;
    _nomeCtrl = TextEditingController(text: s?.nome ?? '');
    _descCtrl = TextEditingController(text: s?.descricao ?? '');
    _endCtrl = TextEditingController(text: s?.endereco ?? '');
    _telCtrl = TextEditingController(text: s?.telefone ?? '');
    _capCtrl = TextEditingController(
      text: s != null ? '${s.capacidade.toInt()}' : '',
    );
    _precoCtrl = TextEditingController(
      text: s != null ? '${s.precoPorHora.toInt()}' : '',
    );
    _fotos = List.from(s?.fotos ?? []);
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    _endCtrl.dispose();
    _telCtrl.dispose();
    _capCtrl.dispose();
    _precoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFoto() async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (img != null) {
      setState(() => _fotos.add(img.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.salao == null) {
        final salao = Salao(
          id: const Uuid().v4(),
          nome: _nomeCtrl.text.trim(),
          descricao: _descCtrl.text.trim(),
          endereco: _endCtrl.text.trim(),
          telefone: _telCtrl.text.trim(),
          capacidade: double.tryParse(_capCtrl.text) ?? 0,
          precoPorHora: double.tryParse(_precoCtrl.text) ?? 0,
          fotos: _fotos,
        );
        await _db.insertSalao(salao);
      } else {
        widget.salao!
          ..nome = _nomeCtrl.text.trim()
          ..descricao = _descCtrl.text.trim()
          ..endereco = _endCtrl.text.trim()
          ..telefone = _telCtrl.text.trim()
          ..capacidade = double.tryParse(_capCtrl.text) ?? 0
          ..precoPorHora = double.tryParse(_precoCtrl.text) ?? 0
          ..fotos = _fotos;
        await _db.updateSalao(widget.salao!);
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.salao != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEdit ? 'Editar Salão' : 'Novo Salão',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _field(
                _nomeCtrl,
                'Nome do Salão *',
                Icons.celebration,
                required: true,
              ),
              const SizedBox(height: 12),
              _field(_descCtrl, 'Descrição', Icons.description),
              const SizedBox(height: 12),
              _field(_endCtrl, 'Endereço', Icons.location_on),
              const SizedBox(height: 12),
              _field(
                _telCtrl,
                'Telefone',
                Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _capCtrl,
                      'Capacidade (pax)',
                      Icons.people,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      _precoCtrl,
                      'Preço/hora (R\$)',
                      Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Fotos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Fotos',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickFoto,
                    icon: const Icon(Icons.add_photo_alternate, size: 18),
                    label: const Text('Adicionar'),
                  ),
                ],
              ),
              if (_fotos.isNotEmpty)
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _fotos.length,
                    itemBuilder: (_, i) => Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(_fotos[i]),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => setState(() => _fotos.removeAt(i)),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: AppTheme.danger,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
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
                      : Text(isEdit ? 'Salvar Alterações' : 'Cadastrar Salão'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
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
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: required
          ? (v) => v!.trim().isEmpty ? 'Campo obrigatório' : null
          : null,
    );
  }
}
