FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json .
RUN npm ci
COPY . .

ARG PUBLIC_SUPABASE_URL
ARG PUBLIC_SUPABASE_ANON_KEY
ENV PUBLIC_SUPABASE_URL=$PUBLIC_SUPABASE_URL
ENV PUBLIC_SUPABASE_ANON_KEY=$PUBLIC_SUPABASE_ANON_KEY

RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
COPY --from=builder /app/build ./build
COPY --from=builder /app/package.json .
COPY --from=builder /app/package-lock.json .
RUN npm ci --omit=dev

EXPOSE 3000
ENV HOST=0.0.0.0
ENV PORT=3000

CMD ["node", "build"]
