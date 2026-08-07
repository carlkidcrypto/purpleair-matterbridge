FROM ubuntu:26.04

ARG MATTERBRIDGE_VERSION=3.10.3
ARG LOGGER_VERSION=1.5.0a2

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/data \
    PATH=/opt/plugin/node_modules/.bin:/opt/matterbridge/bin:/opt/logger-venv/bin:$PATH \
    NODE_ENV=production \
    PURPLEAIR_SETTINGS_FILE=/config/purpleair-settings.json

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates curl \
    && curl --fail --silent --show-error https://deb.nodesource.com/setup_26.x | bash - \
    && apt-get install --yes --no-install-recommends nodejs \
    && npm install --global npm@latest \
    && node --version \
    && npm --version \
    && npx --version \
    && curl --fail --silent --show-error --location https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-unknown-linux-gnu.tar.gz \
        | tar --extract --gzip --strip-components=1 --directory /usr/local/bin uv-x86_64-unknown-linux-gnu/uv \
    && useradd --system --home-dir /data --create-home --shell /usr/sbin/nologin matterbridge \
    && mkdir -p /opt/plugin /opt/matterbridge /opt/logger-venv /data/logger \
    && chown -R matterbridge:matterbridge /opt/plugin /opt/matterbridge /opt/logger-venv /data \
    && chmod 0755 /usr/local/bin/uv \
    && rm -rf /var/lib/apt/lists/*

COPY docker/entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod 0755 /usr/local/bin/docker-entrypoint

USER matterbridge
WORKDIR /opt/plugin
COPY --chown=matterbridge:matterbridge package.json package-lock.json tsconfig.base.json tsconfig.build.json tsconfig.json vitest.config.ts ./
COPY --chown=matterbridge:matterbridge src ./src

RUN npm ci --include=dev --ignore-scripts \
    && npm install --global --prefix /opt/matterbridge --omit=dev matterbridge@${MATTERBRIDGE_VERSION} \
    && mkdir -p node_modules \
    && ln -s /opt/matterbridge/lib/node_modules/matterbridge node_modules/matterbridge \
    && npm run build

RUN uv venv --python 3.14 /opt/logger-venv \
    && uv pip install --python /opt/logger-venv/bin/python --no-cache "purpleair-data-logger==${LOGGER_VERSION}"

EXPOSE 5540/udp 5353/udp
VOLUME ["/data"]
ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]