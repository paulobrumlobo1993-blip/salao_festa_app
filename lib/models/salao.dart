class Salao {
  final String id;
  String nome;
  String descricao;
  String endereco;
  String telefone;
  double capacidade;
  double precoPorHora;
  List<String> fotos;
  List<ItemCatalogo> itens;
  DateTime criadoEm;

  Salao({
    required this.id,
    required this.nome,
    this.descricao = '',
    this.endereco = '',
    this.telefone = '',
    this.capacidade = 0,
    this.precoPorHora = 0,
    List<String>? fotos,
    List<ItemCatalogo>? itens,
    DateTime? criadoEm,
  }) : fotos = fotos ?? [],
       itens = itens ?? [],
       criadoEm = criadoEm ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'endereco': endereco,
      'telefone': telefone,
      'capacidade': capacidade,
      'precoPorHora': precoPorHora,
      'fotos': fotos.join('|'),
      'criadoEm': criadoEm.toIso8601String(),
    };
  }

  factory Salao.fromMap(Map<String, dynamic> map) {
    return Salao(
      id: map['id'],
      nome: map['nome'],
      descricao: map['descricao'] ?? '',
      endereco: map['endereco'] ?? '',
      telefone: map['telefone'] ?? '',
      capacidade: (map['capacidade'] as num).toDouble(),
      precoPorHora: (map['precoPorHora'] as num).toDouble(),
      fotos: map['fotos'] != null && map['fotos'].isNotEmpty
          ? (map['fotos'] as String).split('|')
          : [],
      criadoEm: DateTime.parse(map['criadoEm']),
    );
  }
}

class ItemCatalogo {
  final String id;
  String nome;
  String descricao;
  double preco;
  String? foto;
  String salaoId;

  ItemCatalogo({
    required this.id,
    required this.nome,
    this.descricao = '',
    this.preco = 0,
    this.foto,
    required this.salaoId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'foto': foto,
      'salaoId': salaoId,
    };
  }

  factory ItemCatalogo.fromMap(Map<String, dynamic> map) {
    return ItemCatalogo(
      id: map['id'],
      nome: map['nome'],
      descricao: map['descricao'] ?? '',
      preco: (map['preco'] as num).toDouble(),
      foto: map['foto'],
      salaoId: map['salaoId'],
    );
  }
}
