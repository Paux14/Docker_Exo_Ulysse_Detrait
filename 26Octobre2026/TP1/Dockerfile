FROM node:20.18-alpine3.20 AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci --omit=dev

FROM node:20.18-alpine3.20 AS test
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm npm ci
COPY src ./src
COPY test ./test
RUN npm run lint && npm test

FROM alpine:3.20 AS runtime
ARG APP_VERSION=dev
ARG GIT_SHA=local
LABEL org.opencontainers.image.title="shopapi" \
      org.opencontainers.image.version="${APP_VERSION}" \
      org.opencontainers.image.revision="${GIT_SHA}" \
      org.opencontainers.image.source="https://github.com/Paux14/shopapi"
ENV NODE_ENV=production \
    APP_VERSION=${APP_VERSION}
RUN apk add --no-cache libstdc++=13.2.1_git20240309-r1 \
 && addgroup -g 1000 node \
 && adduser -u 1000 -G node -s /bin/sh -D node
COPY --from=deps /usr/local/bin/node /usr/local/bin/node
WORKDIR /app
COPY --from=deps --chown=node:node /app/node_modules ./node_modules
COPY --from=test --chown=node:node /app/package.json ./
COPY --chown=node:node src ./src
USER 1000:1000
EXPOSE 3000
HEALTHCHECK --interval=5s --timeout=3s --start-period=3s --retries=3 \
  CMD ["wget", "-q", "-O", "/dev/null", "http://127.0.0.1:3000/health"]
CMD ["node", "src/server.js"]
