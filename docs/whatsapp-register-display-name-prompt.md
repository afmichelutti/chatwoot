# Prompt — Registrar nome de exibição aprovado no WhatsApp Cloud API

Cole o conteúdo abaixo no Claude Code rodando **na VPS** que hospeda o Chatwoot (instância `plataformav4`). Este prompt é auto-contido: explica o problema, dá os comandos exatos a executar e diz como reportar de volta.

---

## Contexto que o agente da VPS precisa saber

Você está dentro da VPS que hospeda uma instância do Chatwoot chamada **`plataformav4`**, rodando em containers Docker gerenciados via Portainer.

Há um canal WhatsApp Cloud API (provedor `whatsapp_cloud`) nessa instância com:

- **Phone Number ID:** `1068549406350307`
- **WABA ID:** `1733448027640074`
- **Número:** `+55 12 99673-3354`
- **Nome atual (rejeitado):** Centro Médico São Bento
- **Nome aprovado pendente:** Clínica São Bento

O Business Manager mostra o aviso: *"O novo nome de exibição 'Clínica São Bento' foi aprovado. Registre seu número para começar a usá-lo."* Enquanto o registro não é refeito, clientes recebem **"esse número não tem WhatsApp"** ao tentar mandar mensagem.

A correção é uma única chamada `POST /<phone_number_id>/register` para a Graph API do Meta, usando o PIN de 6 dígitos já salvo pelo Chatwoot em `provider_config.verification_pin`. O Chatwoot tem um service interno (`Whatsapp::WebhookSetupService#register_phone_number`) que faz exatamente isso e é idempotente — não recria a inbox, não mexe no webhook.

**Importante (regras de operação):**
- NÃO desconecte, recrie ou edite a inbox do Chatwoot.
- NÃO imprima o `api_key` (token Meta) inteiro em logs ou no chat — apenas comprimento ou prefixo truncado.
- Confirme antes de qualquer chamada que altere estado externo (fluxo SMS, mudança de PIN). Leitura do DB e a chamada `/register` reutilizando PIN salvo podem prosseguir.

---

## Passo a passo

Execute na ordem. Reporte de volta a saída de cada bloco. Se algo divergir do esperado, **pare** e me passe o erro.

### Passo 1 — Localizar o container Rails do Chatwoot

```bash
docker ps --format '{{.Names}}\t{{.Image}}' | grep -iE 'chatwoot|rails|web|plataformav4'
```

Procure o container que roda a aplicação Rails do Chatwoot (não o `sidekiq`, não o `postgres`, não o `redis`). Guarde o nome — chame de `<CT>` abaixo.

Se houver dúvida sobre qual container é o Rails:

```bash
docker exec <CT> bash -lc 'ls -1 /app/bin 2>/dev/null | head; which bundle; bundle exec rails --version 2>&1 | head -3'
```

Deve listar `rails` e imprimir a versão. Se falhar, é outro container.

### Passo 2 — Inspecionar o canal (leitura, sem expor token)

```bash
docker exec -i <CT> bundle exec rails runner '
  ch = Channel::Whatsapp.where("provider_config->>'\''phone_number_id'\'' = ?", "1068549406350307").first
  abort "Canal nao encontrado para phone_number_id 1068549406350307" unless ch
  pc = ch.provider_config || {}
  puts "channel_id           : #{ch.id}"
  puts "phone_number         : #{ch.phone_number}"
  puts "provider             : #{ch.provider}"
  puts "phone_number_id      : #{pc["phone_number_id"]}"
  puts "business_account_id  : #{pc["business_account_id"]}"
  puts "api_key presente?    : #{pc["api_key"].present?} (len=#{pc["api_key"].to_s.length})"
  puts "verification_pin     : #{pc["verification_pin"].present? ? "[SIM, salvo]" : "[NAO salvo]"}"
  puts "webhook_verify_token : #{pc["webhook_verify_token"].present? ? "presente" : "ausente"}"
'
```

**Saída esperada:** todos os campos preenchidos, `api_key presente? : true`, `verification_pin : [SIM, salvo]`.

Se `verification_pin` estiver **`[NAO salvo]`**, **pare** e reporte — o caminho muda (precisa do fluxo SMS no chip físico, ver "Caminho B" no final).

### Passo 3 — Disparar o registro reutilizando o PIN salvo (Caminho A)

```bash
docker exec -i <CT> bundle exec rails runner '
  ch   = Channel::Whatsapp.where("provider_config->>'\''phone_number_id'\'' = ?", "1068549406350307").first
  waba = ch.provider_config["business_account_id"]
  tok  = ch.provider_config["api_key"]
  svc  = Whatsapp::WebhookSetupService.new(ch, waba, tok)
  result = svc.send(:register_phone_number)
  puts "register_phone_number => #{result.inspect}"
  puts "PIN apos chamada     : #{ch.reload.provider_config["verification_pin"].present? ? "salvo" : "ausente"}"
'
```

**Saída esperada:** algo equivalente a `{"success"=>true}` ou response HTTP 200. Se vier erro do Graph API (ex.: `(#100) Invalid parameter`, `pin mismatch`, `code expired`), copie o JSON completo e reporte — não tente "consertar" com retry cego.

### Passo 4 — Verificar status pós-registro

```bash
docker exec -i <CT> bundle exec rails runner '
  ch  = Channel::Whatsapp.where("provider_config->>'\''phone_number_id'\'' = ?", "1068549406350307").first
  tok = ch.provider_config["api_key"]
  ver = ENV.fetch("WHATSAPP_API_VERSION", "v22.0")
  require "net/http"; require "uri"; require "json"
  uri = URI("https://graph.facebook.com/#{ver}/1068549406350307?fields=verified_name,code_verification_status,display_phone_number,quality_rating,name_status")
  req = Net::HTTP::Get.new(uri); req["Authorization"] = "Bearer #{tok}"
  res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(req) }
  puts "HTTP #{res.code}"
  puts JSON.pretty_generate(JSON.parse(res.body)) rescue puts(res.body)
'
```

**Saída esperada:**
- `verified_name`: `Clínica São Bento`
- `code_verification_status`: `VERIFIED`
- `display_phone_number`: `+55 12 99673-3354` (ou similar formatado)

Se `verified_name` ainda mostrar "Centro Médico São Bento", o registro não pegou — reporte e não execute mais nada.

### Passo 5 — Confirmar que o Chatwoot ainda recebe mensagens

Peça ao usuário humano (não tente automatizar) para mandar uma mensagem de teste de outro WhatsApp para `+55 12 99673-3354` e confirmar que ela aparece na inbox do Chatwoot `plataformav4`. Se aparecer, terminamos.

---

## Caminho B — só se `verification_pin` estiver `[NAO salvo]` no Passo 2

Não execute isto sem confirmação explícita do usuário, porque envolve SMS no chip físico e gravação de PIN novo no DB.

Quando autorizado:

1. Solicitar SMS:
   ```bash
   docker exec -i <CT> bundle exec rails runner '
     ch  = Channel::Whatsapp.where("provider_config->>'\''phone_number_id'\'' = ?", "1068549406350307").first
     tok = ch.provider_config["api_key"]
     ver = ENV.fetch("WHATSAPP_API_VERSION", "v22.0")
     require "net/http"; require "uri"; require "json"
     uri = URI("https://graph.facebook.com/#{ver}/1068549406350307/request_code")
     req = Net::HTTP::Post.new(uri)
     req["Authorization"] = "Bearer #{tok}"
     req["Content-Type"]  = "application/json"
     req.body = { code_method: "SMS", language: "pt_BR" }.to_json
     res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(req) }
     puts "HTTP #{res.code}"; puts res.body
   '
   ```
2. Aguardar o SMS chegar no chip `(12) 99673-3354`. Pedir o código ao usuário.
3. Gerar PIN novo de 6 dígitos (ex.: aleatório), **salvar em `provider_config.verification_pin`** e chamar `/register` com `code` + `pin`. Forneça os blocos exatos somente depois que o código SMS estiver em mãos — peça-o ao usuário sem tentar inferir.

---

## Formato de relato esperado

Para cada passo, devolva:

- Comando exato executado
- Saída (truncando qualquer `api_key` para no máximo 8 caracteres + `...`)
- Sua interpretação curta (1–2 linhas): bateu com o esperado? Próximo passo?

Se um passo falhar, **pare** e reporte. Não execute o seguinte por conta própria.
