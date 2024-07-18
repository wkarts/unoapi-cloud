FROM node:21-alpine AS builder

ENV NODE_ENV=development

RUN apk --update --no-cache add git

WORKDIR /app

# Copiar arquivos de dependências
ADD ./package.json ./package.json
ADD ./yarn.lock ./yarn.lock

# Instalar dependências
RUN yarn

# Adicionar a modificação do arquivo chats.js após a instalação das dependências
# RUN sed -i '/const profilePictureUrl = async/,/return.*url;/ { s/to: jid,/target: jid,\n                to: S_WHATSAPP_NET,/; }' node_modules/@whiskeysockets/baileys/lib/Socket/chats.js

# Verificar o conteúdo do arquivo após a modificação
# RUN echo "Depois da modificação no estágio builder:" && cat node_modules/@whiskeysockets/baileys/lib/Socket/chats.js | grep -A 10 "profilePictureUrl"

# Instale a versão específica do pacote Baileys
RUN yarn add @whiskeysockets/baileys@zennn08/Baileys#profile-picture-url

# Copiar código-fonte e arquivo de configuração do TypeScript
ADD ./src ./src
ADD ./tsconfig.json ./tsconfig.json

# Construir o projeto
RUN yarn build

# Verificar o conteúdo do arquivo no container builder após a construção
# RUN echo "Verificação final do arquivo no builder:" && cat node_modules/@whiskeysockets/baileys/lib/Socket/chats.js | grep -A 10 "profilePictureUrl"

FROM node:21-alpine

LABEL \
  maintainer="Wallace Kleiton <wkarts@gmail.com>" \
  org.opencontainers.image.title="Unoapi Cloud" \
  org.opencontainers.image.description="Unoapi Cloud" \
  org.opencontainers.image.authors="Wallace Kleiton <wkarts@gmail.com>" \
  org.opencontainers.image.url="https://github.com/wkarts/unoapi-cloud" \
  org.opencontainers.image.vendor="https://wwsoftwares.com.br" \
  org.opencontainers.image.licenses="GPLv3"

ENV NODE_ENV=production

RUN addgroup -S u && adduser -S u -G u
WORKDIR /home/u/app

# Copiar os artefatos construídos da fase anterior
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/yarn.lock ./yarn.lock
#COPY --from=builder /app/node_modules ./node_modules

# Instalar apenas as dependências de produção
RUN apk --update --no-cache add git ffmpeg
RUN yarn --production
RUN apk del git

# Aplicar a modificação no container final
# RUN sed -i '/const profilePictureUrl = async/,/return.*url;/ { s/to: jid,/target: jid,\n                to: S_WHATSAPP_NET,/; }' node_modules/@whiskeysockets/baileys/lib/Socket/chats.js

# Verificar o conteúdo do arquivo no container final
# RUN echo "Verificação final do arquivo no container final:" && cat node_modules/@whiskeysockets/baileys/lib/Socket/chats.js | grep -A 10 "profilePictureUrl"

ENTRYPOINT ["yarn", "start"]
