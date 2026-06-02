# Calculadora 3D Print Studio (Flutter + Supabase)

App multiplataforma que replica a [Calculadora 3D Print Studio](https://forja3dprinstudio.com.br/calculadora3d/) com **sync na nuvem** via Supabase.

## Plataformas

- Android, iOS, macOS, Windows, Linux, Web

## Funcionalidades

- Calculadora completa (custos, taxas, G-code, PDF)
- **Login** com e-mail/senha (Supabase Auth)
- **Perfil** — dados da empresa + logo sincronizados
- **Cálculos salvos** — histórico na nuvem + G-code no Storage
- **Orçamentos salvos** — carregar em qualquer dispositivo
- **Login obrigatório** — acesso à calculadora somente com conta autenticada

## Configurar Supabase (grátis)

1. Crie projeto em [supabase.com](https://supabase.com)
2. No **SQL Editor**, execute o arquivo:
   ```
   supabase/migrations/001_initial_schema.sql
   ```
3. Copie **Project URL** e **anon public key** (Settings → API)
4. Configure o app:

```bash
cp .env.example .env
# Edite .env com suas chaves
```

```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
```

5. Em **Authentication → URL Configuration**, adicione redirect URLs do app web se for usar login no browser.

## Executar

```bash
flutter pub get
flutter run -d chrome
flutter run -d macos
flutter run
```

Sem `.env` configurado, o login fica indisponível até configurar o Supabase.

## Deploy Web (grátis)

### GitHub Pages + Supabase

1. No GitHub: **Settings → Secrets → Actions**
2. Adicione `SUPABASE_URL` e `SUPABASE_ANON_KEY`
3. Push na branch `main` — o workflow publica automaticamente

### Vercel / Netlify

Build com variáveis:

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sua-chave
```

## Build mobile/desktop

```bash
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
flutter build macos --release
```

## Arquitetura

```
lib/
├── core/config/        # Env + Supabase init
├── data/repositories/  # Auth, Profile, Calculations, Quotes, Storage
├── domain/             # Models, services, serializers
└── presentation/       # Providers, screens, widgets

supabase/migrations/    # Schema SQL + RLS + Storage
```

## Sync — como usar

1. **Entrar** (canto superior direito)
2. Preencher calculadora / orçamento
3. Barra de nuvem → **Salvar cálculo** / **Salvar orçamento** / **Salvar perfil**
4. Em outro dispositivo: login → **Meus salvos** → toque para carregar
