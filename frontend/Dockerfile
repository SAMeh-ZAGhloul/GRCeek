FROM node:22-slim AS builder
ENV NODE_OPTIONS="--max-old-space-size=8192"
WORKDIR /app

ENV PUBLIC_BACKEND_API_URL=foo

COPY package*.json ./
COPY . .
RUN npm install -g pnpm
RUN pnpm install --frozen-lockfile
RUN pnpm install @sveltejs/adapter-node
RUN pnpm run build
RUN pnpm prune

FROM node:22-slim
ENV NODE_OPTIONS="--max-old-space-size=8192"
WORKDIR /app
COPY --from=builder /app/build build/
COPY --from=builder /app/server server/
COPY --from=builder /app/node_modules node_modules/
COPY package.json .
EXPOSE 3000
ENV NODE_ENV=production
ENV BODY_SIZE_LIMIT=20000000


CMD [ "node", "server" ]
