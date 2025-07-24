FROM node:18-alpine AS builder
ENV NODE_ENV="production"
WORKDIR /app
RUN npm install -g pnpm
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --no-frozen-lockfile --prod

FROM node:18-alpine
ENV NODE_ENV="production"
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
