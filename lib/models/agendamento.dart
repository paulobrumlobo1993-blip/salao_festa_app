class Agendamento {
  final String id;
  String salaoId;
  String nomeCliente;
  String telefoneCliente;
  String email;
  DateTime dataEvento;
  TimeOfDayData horaInicio;
  TimeOfDayData horaFim;
  String tipoEvento;
  int numeroPessoas;
  double valorTotal;
  String status; // confirmado, pendente, cancelado
  String observacoes;
  DateTime criadoEm;

  Agendamento({
    required this.id,
    required this.salaoId,
    required this.nomeCliente,
    this.telefoneCliente = '',
    this.email = '',
    required this.dataEvento,
    required this.horaInicio,
    required this.horaFim,
    this.tipoEvento = '',
    this.numeroPessoas = 0,
    this.valorTotal = 0,
    this.status = 'pendente',
    this.observacoes = '',
    DateTime? criadoEm,
  }) : criadoEm = criadoEm ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'salaoId': salaoId,
      'nomeCliente': nomeCliente,
      'telefoneCliente': telefoneCliente,
      'email': email,
      'dataEvento': dataEvento.toIso8601String(),
      'horaInicioH': horaInicio.hour,
      'horaInicioM': horaInicio.minute,
      'horaFimH': horaFim.hour,
      'horaFimM': horaFim.minute,
      'tipoEvento': tipoEvento,
      'numeroPessoas': numeroPessoas,
      'valorTotal': valorTotal,
      'status': status,
      'observacoes': observacoes,
      'criadoEm': criadoEm.toIso8601String(),
    };
  }

  factory Agendamento.fromMap(Map<String, dynamic> map) {
    return Agendamento(
      id: map['id'],
      salaoId: map['salaoId'],
      nomeCliente: map['nomeCliente'],
      telefoneCliente: map['telefoneCliente'] ?? '',
      email: map['email'] ?? '',
      dataEvento: DateTime.parse(map['dataEvento']),
      horaInicio: TimeOfDayData(
        hour: map['horaInicioH'],
        minute: map['horaInicioM'],
      ),
      horaFim: TimeOfDayData(hour: map['horaFimH'], minute: map['horaFimM']),
      tipoEvento: map['tipoEvento'] ?? '',
      numeroPessoas: map['numeroPessoas'] ?? 0,
      valorTotal: (map['valorTotal'] as num).toDouble(),
      status: map['status'] ?? 'pendente',
      observacoes: map['observacoes'] ?? '',
      criadoEm: DateTime.parse(map['criadoEm']),
    );
  }
}

class TimeOfDayData {
  final int hour;
  final int minute;

  TimeOfDayData({required this.hour, required this.minute});

  String format() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
