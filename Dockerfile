FROM node:22-bookworm-slim

ARG PI_VERSION=0.80.6
ENV Q_HOME=/data/.q \
    NODE_ENV=production

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    git \
    jq \
  && rm -rf /var/lib/apt/lists/* \
  && npm install -g @earendil-works/pi-coding-agent@${PI_VERSION}

WORKDIR /app
COPY q SYSTEM-PROMPT.md README.md ./
RUN chmod +x /app/q \
  && ln -sf /app/q /usr/local/bin/q \
  && ln -sf /app/q /usr/local/bin/fq \
  && ln -sf /app/q /usr/local/bin/lq \
  && mkdir -p /data/.q

VOLUME ["/data/.q"]
ENTRYPOINT ["q"]
