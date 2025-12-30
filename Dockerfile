FROM lukemathwalker/cargo-chef:latest-rust-1 AS chef
WORKDIR /app

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json
COPY . .
RUN cargo build --release --bin kong-security-api

FROM debian:bookworm-slim AS runtime
RUN apt-get update && apt-get install -y ca-certificates curl && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/target/release/kong-security-api /usr/local/bin

ENV MONGODB_URI=mongodb+srv://space_user:yNPBfuIk266JjjjO@clusterdbmongoatlas.mc74nzn.mongodb.net/kong-security-api?retryWrites=true&w=majority&appName=ClusterDbMongoAtlas
ENV MONGODB_DB=kong_security
ENV REDIS_URL=redis://default:Lae4YcunqwOoq0YjfnWuJAo9xpSipq1I@redis-11476.c61.us-east-1-3.ec2.cloud.redislabs.com:11476
ENV JWT_SECRET=nQv?J/&dNnB*qni@@KonG
ENV JWT_EXPIRATION_HOURS=2
ENV GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
ENV GOOGLE_CLIENT_SECRET=your-google-client-secret
ENV GOOGLE_REDIRECT_URL=http://localhost:8080/api/auth/google/callback
ENV APPLE_CLIENT_ID=your.apple.client.id
ENV APPLE_CLIENT_SECRET=your-apple-client-secret
ENV APPLE_REDIRECT_URL=http://localhost:8080/api/auth/apple/callback

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1
ENTRYPOINT ["/usr/local/bin/kong-security-api"]
