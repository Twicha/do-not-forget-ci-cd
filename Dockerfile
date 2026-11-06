# Сборка frontend-web
FROM node:22-slim AS web
WORKDIR /web
COPY frontend-web/package*.json ./
RUN npm ci
COPY frontend-web/ ./
RUN npm run build

# Сборка backend
FROM node:20-slim AS api
RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY backend/package*.json ./
RUN npm ci
COPY backend/ ./
RUN npx prisma generate && npm run build && npm prune --omit=dev

# Итоговый образ: Nest отдаёт и API (/api), и статику фронта
FROM node:20-slim
RUN apt-get update && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*
WORKDIR /app
ENV NODE_ENV=production PORT=4200
COPY --from=api /app/package.json ./
COPY --from=api /app/node_modules ./node_modules
COPY --from=api /app/prisma ./prisma
COPY --from=api /app/dist ./dist
COPY --from=web /web/dist ./client
EXPOSE 4200
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/main"]
