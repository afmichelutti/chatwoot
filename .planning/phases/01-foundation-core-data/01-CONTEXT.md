# Phase 1: Foundation & Core Data - Context

**Gathered:** 2026-02-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Auth system (registration, email verification, login, logout, password reset), multi-tenant architecture with complete data isolation, and UI framework (responsive, light/dark mode, pt-BR). This phase delivers the authenticated app shell — no messaging, no inbox, no contacts management.

</domain>

<decisions>
## Implementation Decisions

### Auth Pages & Flow
- Layout das páginas de auth: Claude's discretion (escolher melhor layout)
- Login somente com email/senha — sem login social na v1
- Verificação de email bloqueia acesso — usuário NÃO entra no app até verificar
- Cadastro inclui criação da organização junto (nome, email, senha + nome da empresa em um passo)
- Sessão persistente por 30 dias com checkbox "Lembrar de mim"
- Múltiplas sessões simultâneas permitidas, sem limite de dispositivos
- Emails de verificação e reset de senha já com branding do tenant (logo/cores)
- Reset de senha via link por email (clássico: recebe link, clica, define nova senha)

### Modelo de Tenant
- URL sem identificador de tenant — tenant resolvido pelo usuário logado
- Usuário pode pertencer a múltiplas organizações
- Alternância entre orgs via dropdown no header (estilo Slack/Notion)
- Isolamento de dados row-level com tenant_id em todas as tabelas — Prisma middleware filtra automaticamente
- Qualquer pessoa pode se cadastrar e criar uma organização (self-service)
- Para entrar em organização existente: somente por convite do admin do tenant
- Super-admin da plataforma existe — acesso a todos os tenants, painel administrativo global
- Sem limite de usuários por organização na v1
- Ownership da org: Claude's discretion (transferível ou fixo)

### Shell da UI & Navegação
- Sidebar colapsável (recolhe para só ícones — estilo Linear/Notion)
- Sidebar Fase 1 mínima: Dashboard (vazio), Configurações da Org, Perfil do Usuário
- Header: Claude's discretion (dropdown de org + avatar com menu no mínimo)
- Mobile: Claude's discretion (drawer hamburger ou bottom tab bar)
- Página de configurações da org: Claude's discretion (dados essenciais + lista de membros)
- Perfil do usuário completo: nome, avatar, senha, email, preferências de notificação, idioma
- Breadcrumbs: Claude's discretion
- Loading states: skeleton screens animados

### Tema & Identidade Visual
- Cor primária: verde (WhatsApp vibe, comunicação, crescimento)
- Modo padrão: segue preferência do SO, com toggle Sistema / Light / Dark
- Densidade: compacta — pouco espaçamento, mais informação na tela (estilo Linear/produtividade)
- Tipografia: seguir melhores práticas das skills de design (frontend-design, web-design-guidelines)

### Claude's Discretion
- Layout das páginas de auth (split, centralizado, etc.)
- Composição do header do app
- Navegação mobile (drawer vs bottom tab)
- Escopo das configurações da org na Fase 1
- Breadcrumbs (sim/não baseado na profundidade de navegação)
- Política de ownership de org (transferível ou fixo)
- Tipografia seguindo melhores práticas de design

</decisions>

<specifics>
## Specific Ideas

- Sidebar colapsável tipo Linear — limpa quando recolhida, informativa quando expandida
- Verde como cor primária combina com foco em WhatsApp
- Compacto como o Linear — app de produtividade, agentes precisam ver muita info
- Emails transacionais já com branding do tenant desde o início (não esperar Fase 4)
- Super-admin com visão global de todos os tenants

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-foundation-core-data*
*Context gathered: 2026-02-12*
