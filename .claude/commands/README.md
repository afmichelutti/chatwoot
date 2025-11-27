# Chatwoot Custom Commands

Este diretório contém comandos personalizados para facilitar o desenvolvimento do Chatwoot no Windows usando WSL2.

## 📋 Comandos Disponíveis

### `/start-chatwoot` ou `start-chatwoot.bat`
**Descrição:** Guia completo para iniciar o ambiente de desenvolvimento Chatwoot

**Quando usar:**
- Iniciar o ambiente pela primeira vez no dia
- Depois de reiniciar o computador
- Depois de parar o ambiente

**O que faz:**
- Mostra checklist pré-inicialização
- Guia passo a passo para abrir 3 terminais
- Instruções para iniciar Rails, Sidekiq e Vite
- Troubleshooting de problemas comuns na inicialização

**Duas formas de uso:**

**Forma 1: Slash Command (manual)**
```
/start-chatwoot
```
Mostra instruções detalhadas para iniciar manualmente.

**Forma 2: Script Automático (Windows)**
```cmd
start-chatwoot.bat
```
Executa automaticamente:
- Inicia Redis
- Abre 3 terminais WSL com Rails, Sidekiq e Vite
- Oferece abrir o navegador automaticamente

---

### `/stop-chatwoot` ou `stop-chatwoot.bat`
**Descrição:** Guia para parar todos os processos do ambiente de desenvolvimento

**Quando usar:**
- Fim do dia de trabalho
- Antes de desligar o computador
- Quando quiser liberar recursos

**O que faz:**
- Instruções para parar Rails, Sidekiq e Vite gracefully
- Como parar Redis (opcional)
- Comandos para forçar parada em emergências
- Verificação de que tudo foi parado

**Duas formas de uso:**

**Forma 1: Slash Command (manual)**
```
/stop-chatwoot
```
Mostra instruções detalhadas.

**Forma 2: Script Automático (Windows)**
```cmd
stop-chatwoot.bat
```
Para automaticamente todos os processos e oferece parar Redis.

---

### `/check-chatwoot` ou `check-chatwoot.bat`
**Descrição:** Diagnosticar o estado atual do ambiente de desenvolvimento

**Quando usar:**
- Antes de iniciar desenvolvimento
- Quando algo não está funcionando corretamente
- Para verificar se tudo está rodando
- Debug de problemas

**O que faz:**
- Verifica WSL e diretório correto
- Checa versões (Ruby, Node, pnpm)
- Testa serviços (Redis, PostgreSQL)
- Lista processos rodando
- Verifica portas em uso
- Analisa logs
- Verifica dependências
- Status do Git
- Recursos do sistema

**Duas formas de uso:**

**Forma 1: Slash Command (manual)**
```
/check-chatwoot
```
Mostra lista completa de comandos para executar.

**Forma 2: Script Automático (Windows)**
```cmd
check-chatwoot.bat
```
Executa todas as verificações automaticamente e mostra relatório.

---

### `/debug-automation`
**Descrição:** Debug de automações do Chatwoot que não estão disparando

**Quando usar:**
- Automação não está funcionando
- Mensagens não disparam ações esperadas
- Troubleshooting de regras de automação

**O que faz:**
- Queries SQL para verificar automações
- Verificar mensagens que deveriam disparar
- Analisar timing (retroatividade)
- Diagnosticar condições
- Identificar problemas comuns

**Exemplo:**
```
/debug-automation
```

---

## 🔄 Workflow Típico

### Começar o dia
```bash
/check-chatwoot     # Verificar estado atual
/start-chatwoot     # Iniciar ambiente
```

### Durante o desenvolvimento
```bash
/check-chatwoot     # Se algo não funcionar
```

### Fim do dia
```bash
/stop-chatwoot      # Parar tudo
```

---

## 🆘 Troubleshooting

### Se o ambiente não inicia
```bash
/check-chatwoot     # Diagnosticar o problema
/start-chatwoot     # Ver troubleshooting específico
```

### Se está lento ou travado
```bash
/check-chatwoot     # Ver uso de recursos
/stop-chatwoot      # Parar tudo
/start-chatwoot     # Reiniciar
```

### Se não sabe o estado atual
```bash
/check-chatwoot     # Sempre comece por aqui
```

---

## 📚 Documentação Relacionada

Estes comandos são baseados na documentação completa:

- **Setup completo:** [../docs/SETUP_WINDOWS_WSL.md](../docs/SETUP_WINDOWS_WSL.md)
  - Guia de instalação do zero
  - Configuração completa do ambiente
  - Todos os problemas e soluções

- **Activity-Based Presence:** [../docs/ACTIVITY_BASED_PRESENCE.md](../docs/ACTIVITY_BASED_PRESENCE.md)
  - Documentação técnica da feature
  - Regras de negócio
  - Testes e troubleshooting

---

## 🎯 Estrutura dos Comandos

Cada comando segue um padrão:

```markdown
---
description: Breve descrição do comando
---

# Título do Comando

## Seções:
- Objetivo
- Checklist / Passo a passo
- Problemas comuns
- Verificação
- Referências
```

---

## 🔧 Como Criar Novos Comandos

1. Criar arquivo `.md` em `.claude/commands/`
2. Adicionar frontmatter com `description`
3. Seguir estrutura padrão
4. Adicionar ao README.md

**Exemplo:**
```markdown
---
description: Descrição breve
---

# Título

Conteúdo do comando...
```

---

## 📝 Notas

- Comandos são **guides**, não automações
- Execute os comandos manualmente após ler as instruções
- Consulte a documentação completa para detalhes
- Contribua com melhorias!

---

**Criado em:** 2025-01-22
**Última atualização:** 2025-01-22
