FROM chatwoot/chatwoot:v4.13.0

# instala o nodejs e o yarn para que possamos recompilar os assets do rails
RUN apk update && apk add --no-cache \
    nodejs-current \
    yarn \
    npm

RUN npm install -g pnpm

# coloca o diretório de trabalho na pasta app
WORKDIR /app

# informa o ambiente de build como produção
ENV RAILS_ENV=production

# Increase Node.js heap memory limit to prevent out of memory errors
ENV NODE_OPTIONS="--max-old-space-size=4096"

# copia o arquivo customizado do tailwind
# COPY ./tailwind.config.js /app/tailwind.config.js

# copia a plataforma customizada

COPY ./app /app/app

COPY ./config /app/config

COPY ./db/migrate /app/db/migrate

COPY ./theme /app/theme

# Removed: openai_prompts path no longer exists in v4.11.1 (replaced by Captain system)
# COPY ./enterprise/lib/enterprise/integrations/openai_prompts /app/enterprise/lib/enterprise/integrations/openai_prompts

#COPY ./chatwoot/app/javascript/dashboard/components/ChatList.vue /app/app/javascript/dashboard/components/ChatList.vue

# COPY ./chatwoot/app/javascript/dashboard/components/widgets/forms/PhoneInput.vue /app/app/javascript/dashboard/components/widgets/forms/PhoneInput.vue

# COPY ./chatwoot/app/javascript/dashboard/routes/dashboard/conversation/contact/ConversationForm.vue /app/app/javascript/dashboard/routes/dashboard/conversation/contact/ConversationForm.vue

# COPY ./mailer /app/app/views/devise/mailer

COPY ./public /app/public

# Coloque os arquivos de branding na pasta branding
# COPY branding/*.* /app/public/

# limpa os assets do rails
RUN SECRET_KEY_BASE=precompile_placeholder RAILS_ENV=production bundle exec rake assets:clean

# recompila os assets do rails
RUN SECRET_KEY_BASE=precompile_placeholder RAILS_ENV=production bundle exec rake assets:precompile


####  docker build --no-cache -t afmichelutti/appio_cw_4130:cliente .
####  docker push afmichelutti/appio_cw_4130:cliente
