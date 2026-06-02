# Autenticação — Supabase

## Desativar confirmação de e-mail (recomendado para este app)

Por padrão o Supabase envia um link de confirmação após o cadastro. Enquanto isso estiver ativo, o usuário **não consegue entrar** até clicar no link.

1. Abra o [painel do Supabase](https://supabase.com/dashboard)
2. Selecione o projeto
3. Vá em **Authentication** → **Providers** → **Email**
4. **Desmarque** a opção **Confirm email**
5. Salve

Depois disso, novos cadastros entram direto, sem e-mail de confirmação.

## Conta já criada com confirmação pendente

Se você se cadastrou antes de desativar a confirmação, escolha uma opção:

### Opção A — Confirmar manualmente no painel

1. **Authentication** → **Users**
2. Abra o usuário
3. Marque o e-mail como confirmado / use **Confirm user**

### Opção B — SQL (substitua o e-mail)

```sql
update auth.users
set email_confirmed_at = now(),
    confirmed_at = now()
where email = 'seu@email.com';
```

## URLs de redirect (web)

Em **Authentication** → **URL Configuration**, adicione:

- `https://kdastudio.github.io/calculator3d/`
- `http://localhost:*` (desenvolvimento local, se necessário)

## Erros comuns

| Sintoma | Causa | Solução |
|--------|--------|---------|
| "Erro de autenticação" após cadastro | Confirmação de e-mail ativa | Desative **Confirm email** (acima) |
| "E-mail ou senha inválidos" logo após criar conta | Conta ainda não confirmada | Confirme o link ou desative confirmação |
| Botão Entrar desabilitado | `.env` / secrets sem Supabase | Configure `SUPABASE_URL` e `SUPABASE_ANON_KEY` |
