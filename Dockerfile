FROM node:lts AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends jq && rm -rf /var/lib/apt/lists/*
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
RUN ./vulnerable-packages.sh

FROM nginx:stable-alpine
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY --from=builder /app/dist /usr/share/nginx/html
COPY --from=builder /app/vulnerable_modules /app/node_modules
COPY default.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /entrypoint.sh
RUN chown -R appuser:appgroup /usr/share/nginx/html /app /entrypoint.sh
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD wget -qO- http://localhost/ || exit 1
USER appuser
ENTRYPOINT ["/entrypoint.sh"]
