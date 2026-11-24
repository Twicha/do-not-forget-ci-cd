# Сборка backend. Контекст — корень do-not-forget (см. docker-compose.yml). Фронт (Next) собирается отдельно: frontend-web/Dockerfile, сервис web
FROM node:20-slim AS api
RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY backend/package*.json ./
# Кэш npm переживает сборки. Часть соединений к registry.npmjs.org с VPS виснет: короткий таймаут и быстрые повторы вместо 5 минут ожидания
RUN --mount=type=cache,target=/root/.npm npm ci --prefer-offline --no-audit --no-fund --fetch-timeout=30000 --fetch-retries=5 --fetch-retry-mintimeout=2000 --fetch-retry-maxtimeout=10000
COPY backend/ ./
RUN npx prisma generate && npm run build && npm prune --omit=dev

# Итоговый образ: Nest отдаёт API (/api) и загруженные файлы (/uploads)
FROM node:20-slim
RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*
WORKDIR /app
ENV NODE_ENV=production PORT=4200
COPY --from=api /app/package.json ./
COPY --from=api /app/node_modules ./node_modules
COPY --from=api /app/prisma ./prisma
COPY --from=api /app/dist ./dist
EXPOSE 4200
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/main"]
