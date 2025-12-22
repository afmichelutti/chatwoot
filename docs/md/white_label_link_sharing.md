# White Label - Customizar Preview de Links Compartilhados

**Data:** 2025-11-28
**Problema:** Links compartilhados mostram "Chatwoot is a customer support solution..." em vez da descrição da Omniflex
**Solução:** Customizar meta tags Open Graph e Twitter Cards

---

## 🔍 Problema Identificado

Quando você compartilha um link do Chatwoot (ex: link de conversa), a preview mostra:

```
Título: Omniflex ✅ (já customizado)
Descrição: "Chatwoot is a customer support solution that helps companies..." ❌ (texto padrão)
URL: lecard.omniflex.com.br ✅
```

**Exemplo:**
```
https://lecard.omniflex.com.br/app/accounts/1/conversations/600382
```

Preview no WhatsApp/Instagram/Facebook mostra a descrição genérica do Chatwoot.

---

## 🎯 Objetivo

Customizar a preview para mostrar:

```
Título: Omniflex - Atendimento ao Cliente ✅
Descrição: Sistema de atendimento ao cliente da Omniflex. Respondemos em instantes! ✅
Imagem: Logo da Omniflex ✅
URL: lecard.omniflex.com.br ✅
```

---

## ✅ Solução Implementada

### 1. **Criar initializer de White Label**

**Arquivo criado:** `config/initializers/white_label.rb`

```ruby
# White Label Configuration for Omniflex
# This file customizes Chatwoot branding to Omniflex

Rails.application.config.to_prepare do
  # Override default brand name
  GlobalConfig.class_eval do
    def self.get(key, default = nil)
      case key
      when 'BRAND_NAME'
        ENV.fetch('CHATWOOT_BRAND_NAME', 'Omniflex')
      when 'BRAND_URL'
        ENV.fetch('CHATWOOT_BRAND_URL', 'https://lecard.omniflex.com.br')
      else
        super
      end
    end
  end
end

# Set default meta tags for Open Graph
module DefaultMetaTags
  def default_meta_tags
    {
      site: 'Omniflex',
      title: 'Omniflex - Atendimento ao Cliente',
      description: 'Sistema de atendimento ao cliente da Omniflex. Respondemos em instantes!',
      keywords: 'atendimento, suporte, chat, omniflex',
      og: {
        title: 'Omniflex',
        description: 'Sistema de atendimento ao cliente da Omniflex. Respondemos em instantes!',
        type: 'website',
        site_name: 'Omniflex'
      },
      twitter: {
        card: 'summary_large_image',
        title: 'Omniflex',
        description: 'Sistema de atendimento ao cliente da Omniflex. Respondemos em instantes!'
      }
    }
  end
end

ActionView::Base.include DefaultMetaTags
```

---

## 🔧 Implementação Alternativa (Modificar Views)

Se a solução acima não funcionar, modifique diretamente as views:

### **Opção 1: Modificar layout principal**

**Arquivo:** `app/views/layouts/vueapp.html.erb` (ou similar)

Procure por:

```erb
<meta name="description" content="Chatwoot is a customer support solution...">
<meta property="og:description" content="Chatwoot is a customer support solution...">
```

Substitua por:

```erb
<meta name="description" content="Sistema de atendimento ao cliente da Omniflex. Respondemos em instantes!">
<meta property="og:description" content="Sistema de atendimento ao cliente da Omniflex. Respondemos em instantes!">
<meta property="og:title" content="Omniflex - Atendimento ao Cliente">
<meta property="og:image" content="<%= asset_url('brand-assets/logo.svg') %>">
<meta property="og:site_name" content="Omniflex">

<!-- Twitter Cards -->
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="Omniflex - Atendimento ao Cliente">
<meta name="twitter:description" content="Sistema de atendimento ao cliente da Omniflex. Respondemos em instantes!">
<meta name="twitter:image" content="<%= asset_url('brand-assets/logo.svg') %>">
```

---

### **Opção 2: Adicionar no index.html (Vue App)**

**Arquivo:** `public/index.html` (se existir)

Adicione no `<head>`:

```html
<!-- Open Graph / Facebook -->
<meta property="og:type" content="website">
<meta property="og:title" content="Omniflex - Atendimento ao Cliente">
<meta property="og:description" content="Sistema de atendimento ao cliente da Omniflex. Respondemos em instantes!">
<meta property="og:image" content="/brand-assets/logo.svg">
<meta property="og:site_name" content="Omniflex">

<!-- Twitter -->
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="Omniflex - Atendimento ao Cliente">
<meta name="twitter:description" content="Sistema de atendimento ao cliente da Omniflex. Respondemos em instantes!">
<meta name="twitter:image" content="/brand-assets/logo.svg">
```

---

## 🌐 Variáveis de Ambiente (Opcional)

Se quiser tornar configurável via ENV:

**Adicione no `.env` ou Docker:**

```bash
CHATWOOT_BRAND_NAME=Omniflex
CHATWOOT_BRAND_DESCRIPTION="Sistema de atendimento ao cliente da Omniflex. Respondemos em instantes!"
CHATWOOT_BRAND_URL=https://lecard.omniflex.com.br
CHATWOOT_BRAND_LOGO_URL=https://lecard.omniflex.com.br/brand-assets/logo.svg
```

**Use no initializer:**

```ruby
Rails.application.config.to_prepare do
  module DefaultMetaTags
    def default_meta_tags
      {
        site: ENV.fetch('CHATWOOT_BRAND_NAME', 'Chatwoot'),
        title: ENV.fetch('CHATWOOT_BRAND_NAME', 'Chatwoot'),
        description: ENV.fetch('CHATWOOT_BRAND_DESCRIPTION', 'Customer support platform'),
        og: {
          title: ENV.fetch('CHATWOOT_BRAND_NAME', 'Chatwoot'),
          description: ENV.fetch('CHATWOOT_BRAND_DESCRIPTION', 'Customer support platform'),
          type: 'website',
          url: ENV.fetch('CHATWOOT_BRAND_URL', request.base_url),
          image: ENV.fetch('CHATWOOT_BRAND_LOGO_URL', asset_url('logo.svg')),
          site_name: ENV.fetch('CHATWOOT_BRAND_NAME', 'Chatwoot')
        },
        twitter: {
          card: 'summary_large_image',
          title: ENV.fetch('CHATWOOT_BRAND_NAME', 'Chatwoot'),
          description: ENV.fetch('CHATWOOT_BRAND_DESCRIPTION', 'Customer support platform'),
          image: ENV.fetch('CHATWOOT_BRAND_LOGO_URL', asset_url('logo.svg'))
        }
      }
    end
  end

  ActionView::Base.include DefaultMetaTags
end
```

---

## 📋 Checklist de White Label Completo

### Meta Tags (este documento):
- [x] Criar `config/initializers/white_label.rb`
- [ ] Testar preview no WhatsApp
- [ ] Testar preview no Facebook
- [ ] Testar preview no Instagram
- [ ] Testar preview no LinkedIn
- [ ] Verificar com ferramenta: https://developers.facebook.com/tools/debug/

### Outros elementos de White Label:
- [x] Logos (`public/brand-assets/`)
- [x] Favicons (`public/favicon*.png`)
- [x] Título da aplicação (`app.json`)
- [ ] Templates de email (`app/views/devise/mailer/`)
- [ ] Rodapé (footer)
- [ ] Nome da empresa nos textos da UI

---

## 🧪 Como Testar

### 1. **Facebook/Instagram Debugger:**

Acesse: https://developers.facebook.com/tools/debug/

Cole a URL: `https://lecard.omniflex.com.br/app/accounts/1/conversations/600382`

Clique em "Buscar novas informações" para ver a preview atualizada.

---

### 2. **LinkedIn Post Inspector:**

Acesse: https://www.linkedin.com/post-inspector/

Cole a URL e veja a preview.

---

### 3. **Twitter Card Validator:**

Acesse: https://cards-dev.twitter.com/validator

Cole a URL e veja a preview.

---

### 4. **WhatsApp (manual):**

Envie o link para você mesmo no WhatsApp e veja a preview gerada.

---

## 🔍 Debugging

### Ver quais meta tags estão sendo geradas:

```bash
# No navegador, inspecione o <head>
curl -s https://lecard.omniflex.com.br/app/accounts/1/conversations/600382 | grep -i "og:description"
```

**Deve retornar:**
```html
<meta property="og:description" content="Sistema de atendimento ao cliente da Omniflex. Respondemos em instantes!">
```

---

### Verificar no Rails Console:

```ruby
# Ver configurações de brand
ENV['CHATWOOT_BRAND_NAME']
ENV['CHATWOOT_BRAND_DESCRIPTION']

# Verificar initializer carregado
Rails.application.config.to_prepare
```

---

## 🚀 Deploy

### 1. **Commit das mudanças:**

```bash
git add config/initializers/white_label.rb
git commit -m "feat: Add white label configuration for link sharing"
```

### 2. **Build Docker:**

```bash
docker build --no-cache -t afmichelutti/omniflex_cw_470:latest .
docker push afmichelutti/omniflex_cw_470:latest
```

### 3. **Deploy no Portainer:**

- Atualizar stack
- Recriar containers
- Verificar se initializer foi carregado:
  ```bash
  docker exec -it <container> ls -la config/initializers/white_label.rb
  ```

### 4. **Limpar cache do Facebook:**

Acesse: https://developers.facebook.com/tools/debug/

Cole a URL e clique em "Buscar novas informações" para forçar atualização do cache.

---

## ⚠️ Limitações Conhecidas

### 1. **Cache de redes sociais**

Facebook/Instagram/LinkedIn fazem cache da preview por até **7 dias**.

**Solução:** Use o debugger das respectivas plataformas para forçar atualização.

---

### 2. **Imagem não aparece**

Se a imagem do logo não aparecer na preview:

**Motivos possíveis:**
- Arquivo SVG não é suportado (use PNG/JPG)
- URL não é absoluta (precisa ser `https://...`)
- Tamanho inadequado (recomendado: 1200x630px)

**Solução:**

Criar imagem específica para Open Graph:

```bash
# No servidor, gerar PNG do logo
convert public/brand-assets/logo.svg -resize 1200x630 public/og-image.png
```

E usar no meta tag:

```erb
<meta property="og:image" content="<%= asset_url('og-image.png') %>">
```

---

### 3. **Preview diferente em cada plataforma**

Cada plataforma tem requisitos específicos:

| Plataforma | Tamanho Recomendado | Proporção |
|-----------|-------------------|-----------|
| Facebook | 1200x630px | 1.91:1 |
| Twitter | 1200x675px | 16:9 |
| LinkedIn | 1200x627px | 1.91:1 |
| WhatsApp | 400x400px (min) | Qualquer |

**Solução:** Criar múltiplas versões da imagem ou usar uma versão universal de 1200x630px.

---

## 📝 Notas Técnicas

### Por que usar `config.to_prepare` em vez de `config.after_initialize`?

- `to_prepare` roda **toda vez** que o código é recarregado (desenvolvimento e produção)
- `after_initialize` roda **apenas uma vez** no boot
- Para modificar classes existentes (como `GlobalConfig`), precisamos de `to_prepare`

---

### Por que incluir módulo em `ActionView::Base`?

- Torna os métodos disponíveis em **todas as views**
- Permite usar `default_meta_tags` em qualquer template ERB
- Mais flexível que modificar layout específico

---

### Por que não modificar diretamente o código do Chatwoot?

- ✅ Initializer é **menos invasivo** (não mexe no core)
- ✅ Mais **fácil de manter** em upgrades
- ✅ Pode ser **desabilitado** facilmente (renomear arquivo)
- ✅ **Separação de concerns** (customização separada do core)

---

## 🔗 Referências

- [Open Graph Protocol](https://ogp.me/)
- [Twitter Cards](https://developer.twitter.com/en/docs/twitter-for-websites/cards/overview/abouts-cards)
- [Facebook Sharing Debugger](https://developers.facebook.com/tools/debug/)
- [LinkedIn Post Inspector](https://www.linkedin.com/post-inspector/)

---

## 📊 Resultado Esperado

**Antes:**
```
Título: Omniflex
Descrição: Chatwoot is a customer support solution that helps companies engage customers...
```

**Depois:**
```
Título: Omniflex - Atendimento ao Cliente
Descrição: Sistema de atendimento ao cliente da Omniflex. Respondemos em instantes!
Imagem: [Logo da Omniflex]
```

---

**Autor:** Claude Code
**Referência:** White Label customization for link sharing previews
