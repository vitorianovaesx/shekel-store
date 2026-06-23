# ShekelStore — Documentação de Setup

## Proposta

**ShekelStore** é uma loja virtual de shekels (moeda virtual) onde usuários podem:
- Investir em ativos virtuais usando a bússola para apontar para Israel
- Compartilhar resultados e conquistas
- Personalizar o perfil com foto tirada pela câmera

Nenhum dinheiro real é utilizado, apenas shekels virtuais.

---

## Tecnologias Utilizadas

| Camada | Tecnologia |
|--------|-----------|
| Mobile | Flutter (Dart) |
| Banco de dados | SQLite via sqflite (local no dispositivo) |
| Backup automático | Cópia periódica do banco a cada 5 min (`BackupService`) |
| API Externa | open.er-api.com (cotações ILS) |
| Notificações | flutter_local_notifications |
| Compartilhamento | share_plus |
| Hardware (câmera) | image_picker |
| Hardware (sensor) | sensors_plus (magnetômetro — bússola para Jerusalém) |
| Estado | Provider |
| Fontes | Google Fonts (Poppins) |

---

## Requisitos Mínimos Atendidos

| Requisito | Implementação |
|-----------|---------------|
| App mobile (não web) | Flutter nativo Android/iOS |
| Múltiplas telas (>2) | 15+ telas: Splash, Login, Cadastro, Home, Loja de Sião, Rabbi Chat, Store, Detalhe Item, Cassino, Cara ou Coroa, Dado, Caça-Níquel, Mercado, Perfil, Histórico |
| Navegação funcional | Named routes + Navigator.push |
| Backend | SQLite local via sqflite (sem dependência de servidor externo) |
| Banco de dados | SQLite — tabelas: users, items, user_items, bets, transactions |
| API externa | ExchangeRate API (open.er-api.com/v6/latest/ILS) |
| Notificações | Notificações locais para vitórias, derrotas, compras e bônus diário |
| Compartilhamento | share_plus: compartilha resultados de apostas, itens comprados e perfil |
| Hardware | Câmera (image_picker) para foto de perfil + magnetômetro (sensors_plus) para bússola |

---

## Pré-requisitos

- Flutter SDK 3.3.0+
- Android Studio / Xcode para emuladores

---

## Instalação e Execução

```bash
# 1. Instalar dependências
flutter pub get

# 2. Rodar no Android (emulador ou dispositivo)
flutter run

# 3. Rodar no iOS (requer Mac com Xcode)
cd ios && pod install && cd ..
flutter run -d ios

# 4. Build APK para Android
flutter build apk --release
```

Nenhuma configuração adicional é necessária. O banco de dados SQLite é criado automaticamente na primeira execução e populado com os itens da loja.

---

## Banco de Dados

O banco SQLite (`shekelstore.db`) é criado no dispositivo via `sqflite`. Estrutura:

| Tabela | Descrição |
|--------|-----------|
| `users` | Usuários (id, username, email, hash de senha, saldo, stats) |
| `items` | Itens disponíveis na loja (pré-populados no onCreate) |
| `user_items` | Itens adquiridos por cada usuário |
| `bets` | Histórico de apostas nos jogos de cassino |
| `transactions` | Registro de todas as movimentações de saldo |

### Backup automático

O `BackupService` copia o arquivo `.db` a cada **5 minutos** para `<documentos>/backups/`. São mantidas as **3 cópias mais recentes**; arquivos mais antigos são excluídos automaticamente.

---

## Estrutura do Projeto

```
lib/
├── main.dart              # Ponto de entrada — inicia notificações e backup
├── app.dart               # MaterialApp + rotas
├── core/
│   ├── constants.dart     # Constantes (URLs, valores do jogo)
│   └── theme.dart         # Tema dourado/escuro
├── models/                # Modelos de dados
├── services/
│   ├── local_db_service.dart   # CRUD SQLite
│   ├── auth_service.dart       # Sessão com SharedPreferences
│   ├── backup_service.dart     # Backup periódico do banco
│   ├── exchange_rate_service.dart  # API externa de cotações
│   ├── notification_service.dart   # Notificações locais
│   ├── compass_service.dart        # Magnetômetro (bússola)
│   └── rabbi_ai_service.dart       # Conselheiro de investimentos
├── providers/             # Gerenciamento de estado (Provider)
├── screens/               # Telas do app
│   ├── auth/              # Login e Cadastro
│   ├── casino/            # Cassino (3 jogos)
│   ├── investments/       # Loja de Sião + Rabbi Chat
│   ├── store/             # Loja e detalhe de item
│   └── profile/           # Perfil e histórico
└── widgets/               # Componentes reutilizáveis
```

---

## Fluxo Principal

```
Splash → Login/Cadastro → Home (Dashboard)
                              ↓
          ┌───────────────────┼──────────────────┐
       Loja de Sião        Cassino            Mercado
    (investimentos +      (3 jogos)        (cotações ILS)
      bússola Israel)         ↓
          ↓            Jogo específico
     Rabbi Chat         (apostar/compartilhar)
     (conselheiro)
          ↓
       Store → Detalhe Item (comprar/compartilhar)
          ↓
       Perfil → Histórico
```

---

## API Externa

**Endpoint:** `https://open.er-api.com/v6/latest/ILS`

Exibe cotações em tempo real do Shekel Israelense (ILS) contra mais de 160 moedas mundiais. Não requer chave de API. Os dados são cacheados por 30 minutos no app.

---

## Funcionalidades de Jogo

### Cara ou Coroa
- 50% de chance de ganhar
- Multiplicador: 2x

### Dado Sortudo
- 1/6 de chance de acertar o número
- Multiplicador: 5x

### Caça-Níquel
- Jackpot (7️⃣7️⃣7️⃣ ou 💎💎💎): 10x
- Triple (3 iguais): 5x
- Double (2 iguais): 2x

---

## Bônus

- **Bônus de registro:** 1000 shekels ao criar conta
- **Bônus diário:** 100 shekels (1x por dia)
