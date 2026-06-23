# ShekelStore

Aplicação mobile de loja virtual e cassino com shekels — moeda fictícia com cotação real.

Desenvolvida em Flutter como Atividade Ponderada 4 do curso de Engenharia de Software — Inteli.

---

## Funcionalidades

- Jogos de cassino: Cara ou Coroa, Dado Sortudo, Caça-Níquel
- Loja de itens virtuais compráveis com shekels ganhos
- Cotações em tempo real do Shekel Israelense (ILS) via API externa
- Investimentos virtuais com bússola que usa o magnetômetro do celular para apontar para Jerusalém
- Conselheiro financeiro "Rabi Mordechai" com dicas do dia
- Foto de perfil tirada pela câmera do dispositivo
- Notificações locais para vitórias, compras e bônus diário
- Compartilhamento de resultados via apps nativos
- Backup automático do banco de dados a cada 5 minutos

---

## Stack

| Camada | Tecnologia |
|--------|-----------|
| Mobile | Flutter (Dart) |
| Banco de dados | SQLite via sqflite (local) |
| Backup | BackupService — cópia periódica a cada 5 min |
| API externa | open.er-api.com (cotações ILS) |
| Notificações | flutter_local_notifications |
| Compartilhamento | share_plus |
| Câmera | image_picker |
| Sensor | sensors_plus (magnetômetro) |
| Estado | Provider |

---

## Execução

```bash
flutter pub get
flutter run
```

Nenhuma configuração extra é necessária. O banco SQLite é criado automaticamente na primeira execução.

Para detalhes de estrutura, banco de dados e build de release, veja [SETUP.md](SETUP.md).
