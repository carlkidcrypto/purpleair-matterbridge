FROM ubuntu:26.04

ARG MATTERBRIDGE_VERSION=3.10.3
ARG LOGGER_VERSION=1.5.0a2

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/data \
    PATH=/opt/plugin/node_modules/.bin:/opt/matterbridge/node_modules/.bin:/opt/logger-venv/bin:$PATH \
    NODE_ENV=production \
    LOGGER_ARGS=

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates curl \
    && curl --fail --silent --show-error https://deb.nodesource.com/setup_26.x | bash - \
    && apt-get install --yes --no-install-recommends nodejs \
    && curl --fail --silent --show-error --location https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-unknown-linux-gnu.tar.gz \
        | tar --extract --gzip --strip-components=1 --directory /usr/local/bin uv-x86_64-unknown-linux-gnu/uv \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/plugin
COPY package.json package-lock.json tsconfig.base.json tsconfig.build.json tsconfig.json vitest.config.ts ./
COPY src ./src

RUN npm ci --include=dev --ignore-scripts \
    && npm install --prefix /opt/matterbridge --omit=dev matterbridge@${MATTERBRIDGE_VERSION} \
    && mkdir -p node_modules \
    && ln -s /opt/matterbridge/node_modules/matterbridge node_modules/matterbridge \
    && npm run build

RUN uv venv --python 3.14 /opt/logger-venv \
    && uv pip install --python /opt/logger-venv/bin/python --no-cache "purpleair-data-logger==${LOGGER_VERSION}"

RUN mkdir -p /data/matterbridge /data/logger
COPY docker/entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod 0755 /usr/local/bin/docker-entrypoint \
    && useradd --system --home-dir /data --create-home --shell /usr/sbin/nologin matterbridge \
    && chown -R matterbridge:matterbridge /data /opt/plugin /opt/matterbridge /opt/logger-venv

USER matterbridge
EXPOSE 5540/udp 5353/udp
VOLUME ["/data/matterbridge", "/data/logger"]
ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]