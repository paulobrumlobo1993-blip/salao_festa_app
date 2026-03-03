# Salão Festa App 🎉

Aplicativo em **Flutter** para gerenciamento de **salões de festa**, com **cadastro de salões**, **catálogo de itens**, **agendamentos** e **calendário**.

## ✨ Funcionalidades

### 🏛️ Salões
- Cadastrar / editar / excluir salões
- Adicionar fotos do salão (galeria)
- Informações: nome, descrição, endereço, telefone, capacidade, preço por hora

### 🧾 Catálogo (por salão)
- Adicionar itens do catálogo (ex.: buffet, brinquedos, decoração)
- Foto, descrição e preço por item

### 📅 Agendamentos
- Criar / editar / excluir agendamentos
- Status: **Pendente**, **Confirmado**, **Cancelado**
- Campos: data, horário (início/fim), cliente, telefone, e-mail, tipo de evento, nº pessoas, valor total, observações
- Filtro por status

### 🗓️ Calendário
- Visualização mensal com marcação de dias com eventos
- Lista de agendamentos do dia selecionado
- Filtro por salão no calendário

## 🧱 Tecnologias
- Flutter (Material 3)
- SQLite com `sqflite`
- `table_calendar` (calendário)
- `image_picker` (fotos)
- `intl` (formatação de datas)

## 📂 Estrutura do projeto (principal)
- `lib/screens/` telas do app
- `lib/models/` modelos (Salão, Agendamento, Item de catálogo)
- `lib/services/` acesso ao banco (SQLite)
- `lib/utils/` tema e utilidades

## ▶️ Como rodar
1. Instale o Flutter e configure o ambiente.
2. No terminal, dentro do projeto:

```bash
flutter pub get
flutter run
