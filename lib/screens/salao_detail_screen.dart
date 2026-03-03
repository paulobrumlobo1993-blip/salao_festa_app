import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/salao.dart';
import '../services/database_service.dart';
import '../utils/app_theme.dart';

class SalaoDetailScreen extends StatefulWidget {
  final Salao salao;

  const SalaoDetailScreen({super.key, required this.salao});

  @override
  State<SalaoDetailScreen> createState() => _SalaoDetailScreenState();
}

class _SalaoDetailScreenState extends State<SalaoDetailScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseService();
  late TabController _tabController;
  late Salao _salao;

  @override
  void initState() {
    super.initState();
    _salao = widget.salao;
    _tabController = TabController(length: 2, vsync: this);
    _reload();
  }

  Future<void> _reload() async {
    final s = await _db.getSalaoById(_salao.id);
    if (s != null) setState(() => _salao = s);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openItemForm([ItemCatalogo? item]) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ItemFormSheet(salaoId: _salao.id, item: item),
    );
    if (result == true) _reload();
  }

  Future<void> _deleteItem(ItemCatalogo item) async {
    await _db.deleteItem(item.id);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  /* handled from parent */
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_salao.nome),
              background: _salao.fotos.isNotEmpty
                  ? PageView.builder(
                      itemCount: _salao.fotos.length,
                      itemBuilder: (_, i) => Image.file(
                        File(_salao.fotos[i]),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _bgPlaceholder(),
                      ),
                    )
                  : _bgPlaceholder(),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_salao.descricao.isNotEmpty)
                    Text(
                      _salao.descricao,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_salao.endereco.isNotEmpty)
                        _chip(Icons.location_on, _salao.endereco),
                      if (_salao.telefone.isNotEmpty)
                        _chip(Icons.phone, _salao.telefone),
                      _chip(
                        Icons.people,
                        '${_salao.capacidade.toInt()} pessoas',
                      ),
                      _chip(
                        Icons.attach_money,
                        'R\$ ${_salao.precoPorHora.toStringAsFixed(0)}/h',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Fotos', icon: Icon(Icons.photo_library, size: 18)),
                  Tab(text: 'Catálogo', icon: Icon(Icons.category, size: 18)),
                ],
                indicatorColor: AppTheme.primary,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── TAB FOTOS ──
            _salao.fotos.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhuma foto',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                    itemCount: _salao.fotos.length,
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_salao.fotos[i]),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),

            // ── TAB CATÁLOGO ──
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_salao.itens.length} ${_salao.itens.length == 1 ? 'item' : 'itens'}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openItemForm(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Adicionar Item'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _salao.itens.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhum item no catálogo',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemCount: _salao.itens.length,
                          itemBuilder: (_, i) => _ItemCard(
                            item: _salao.itens[i],
                            onEdit: () => _openItemForm(_salao.itens[i]),
                            onDelete: () => _deleteItem(_salao.itens[i]),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bgPlaceholder() => Container(
    color: AppTheme.surfaceLight,
    child: const Center(
      child: Icon(Icons.celebration, color: AppTheme.primary, size: 80),
    ),
  );

  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppTheme.cardBg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.primary, size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      ],
    ),
  );
}

class _ItemCard extends StatelessWidget {
  final ItemCatalogo item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: item.foto != null
              ? Image.file(
                  File(item.foto!),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _iconBox(),
                )
              : _iconBox(),
        ),
        title: Text(
          item.nome,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.descricao.isNotEmpty)
              Text(
                item.descricao,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              'R\$ ${item.preco.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primary, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.danger, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox() => Container(
    width: 56,
    height: 56,
    color: AppTheme.surfaceLight,
    child: const Icon(Icons.inventory_2, color: AppTheme.primary),
  );
}

// ─── ITEM FORM ────────────────────────────────────────────────────────────────
class ItemFormSheet extends StatefulWidget {
  final String salaoId;
  final ItemCatalogo? item;

  const ItemFormSheet({super.key, required this.salaoId, this.item});

  @override
  State<ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends State<ItemFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();
  final _picker = ImagePicker();

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _precoCtrl;
  String? _foto;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    _nomeCtrl = TextEditingController(text: it?.nome ?? '');
    _descCtrl = TextEditingController(text: it?.descricao ?? '');
    _precoCtrl = TextEditingController(text: it != null ? '${it.preco}' : '');
    _foto = it?.foto;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    _precoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFoto() async {
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (img != null) setState(() => _foto = img.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.item == null) {
        final item = ItemCatalogo(
          id: const Uuid().v4(),
          nome: _nomeCtrl.text.trim(),
          descricao: _descCtrl.text.trim(),
          preco: double.tryParse(_precoCtrl.text) ?? 0,
          foto: _foto,
          salaoId: widget.salaoId,
        );
        await _db.insertItem(item);
      } else {
        widget.item!
          ..nome = _nomeCtrl.text.trim()
          ..descricao = _descCtrl.text.trim()
          ..preco = double.tryParse(_precoCtrl.text) ?? 0
          ..foto = _foto;
        await _db.updateItem(widget.item!);
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                widget.item == null ? 'Novo Item' : 'Editar Item',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Foto
              Center(
                child: GestureDetector(
                  onTap: _pickFoto,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.4),
                      ),
                    ),
                    child: _foto != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_foto!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image),
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                color: AppTheme.primary,
                                size: 32,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Foto',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Nome do Item *',
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _precoCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Preço (R\$)',
                  prefixIcon: Icon(Icons.attach_money),
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
                      : Text(widget.item == null ? 'Adicionar Item' : 'Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppTheme.surface, child: tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate old) => false;
}
