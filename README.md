# 🎬 MovieNest

MovieNest é uma aplicação mobile desenvolvida em Flutter para descobrir filmes e séries, guardar favoritos e consultar detalhes como sinopse, elenco, trailers, plataformas onde ver e recomendações.

O projeto foi desenvolvido no âmbito da unidade curricular de Computação Móvel, usando a API externa do TMDB e Firebase para autenticação e base de dados remota.

## 👥 Equipa

- Diogo Brito - 2024151350
- Diogo Gomes - 2024148451
- Guilherme Garcia - 202300160
- Rafael Junqueira - 2024151531

## 🚀 Funcionalidades principais

- 🔐 Registo e login com email e palavra-passe
- 👤 Perfil de utilizador com edição de nome, foto e password
- 🏠 Página inicial com filmes e séries em destaque
- 🔎 Pesquisa de filmes e séries
- 📈 Pesquisas em tendência obtidas pela API do TMDB
- 🕘 Histórico de pesquisas recentes por utilizador
- 🎭 Exploração por géneros
- ❤️ Sistema de favoritos associado à conta
- 🎬 Página de detalhes com trailer, sinopse, elenco, galeria e recomendações
- 🧑 Perfil dos atores com biografia e obras conhecidas
- 🔔 Sistema de notificações internas

## 🔔 Notificações

A aplicação inclui um sistema de notificações internas guardadas no Firebase Firestore.

As notificações são criadas quando:

- um filme guardado nos favoritos estreia;
- uma série guardada ganha uma nova temporada.

Também existe um botão de demonstração na página de notificações, para permitir apresentar esta funcionalidade sem esperar por uma estreia real.

O utilizador pode ativar ou desativar as notificações no menu de perfil.

## 🌐 API externa

O projeto utiliza a API do TMDB para obter:

- filmes e séries em tendência;
- filmes populares;
- próximos lançamentos;
- resultados de pesquisa;
- géneros;
- detalhes de filmes e séries;
- trailers;
- elenco e equipa técnica;
- imagens;
- recomendações;
- dados de atores.

## 🗄️ Base de dados remota

A aplicação usa Firebase Firestore como base de dados remota.

São guardados na cloud:

- dados do utilizador;
- favoritos;
- notificações;
- preferências, como notificações ativas ou desativadas.

## 🔐 Autenticação

A autenticação é feita com Firebase Authentication.

Funcionalidades disponíveis:

- criar conta;
- iniciar sessão;
- terminar sessão;
- mudar password;
- guardar nome do utilizador;
- atualizar dados do perfil.

## 🛠️ Tecnologias usadas

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- TMDB API
- HTTP
- Image Picker
- URL Launcher

## 📁 Estrutura principal do projeto

```text
lib/
  models/
    app_notification.dart
    movie.dart
  screens/
    favorites_screen.dart
    genre_movies_screen.dart
    home_screen.dart
    login_screen.dart
    main_navigation.dart
    movie_detail_screen.dart
    notifications_screen.dart
    person_profile_screen.dart
    profile_screen.dart
    search_screen.dart
    splash_screen.dart
  services/
    auth_service.dart
    favorite_service.dart
    notification_service.dart
    tmdb_service.dart
  theme/
    app_theme.dart
  widgets/
    movie_card.dart
```

## ▶️ Como executar

1. Instalar as dependências:

```bash
flutter pub get
```

2. Verificar se existe um dispositivo ligado ou emulador ativo:

```bash
flutter devices
```

3. Executar a aplicação:

```bash
flutter run
```

## ✅ Requisitos mínimos do enunciado

| Requisito | Estado |
|---|---|
| Autenticação e registo de utilizadores | ✅ Firebase Authentication |
| Sistema de notificações | ✅ Notificações internas via Firestore |
| Integração com API externa | ✅ TMDB API |
| Base de dados remota | ✅ Cloud Firestore |

## 📌 Notas finais

MovieNest foi pensado como uma app simples e visualmente apelativa para descobrir conteúdos, com dados reais vindos do TMDB e informação persistente associada a cada conta através do Firebase.
