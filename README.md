# Atividade 4DSM GPS

Aplicativo Flutter para registrar localizações, consultar o histórico e visualizar os pontos em um mapa.

## Integrantes

- Caio Araujo

## Funcionalidades

- Coleta manual ou contínua de localizações e armazenamento local.
- Coleta contínua em segundo plano com serviço em primeiro plano no Android.
- Histórico das 100 localizações mais recentes, com opção de atualizar e limpar os registros.
- Mapa interativo com marcadores, enquadramento dos pontos e cache de tiles.

## Executar

```sh
flutter pub get
flutter run
```

No Android e no iOS, conceda as permissões de localização solicitadas pelo sistema. A coleta em segundo plano depende da autorização do usuário e das restrições de execução de cada plataforma.
