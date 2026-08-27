FROM ubuntu:26.04

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
RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint \
    && chmod 0755 /usr/local/bin/docker-entrypoint

USER matterbridge
WORKDIR /opt/plugin
COPY --chown=matterbridge:matterbridge package.json package-lock.json tsconfig.base.json tsconfig.build.json tsconfig.json vitest.config.ts ./
COPY --chown=matterbridge:matterbridge src ./src
COPY --chown=matterbridge:matterbridge docker/package.json /opt/matterbridge-package.json

RUN npm ci --include=dev --ignore-scripts \
    && matterbridge_version="$(node --input-type=commonjs --eval "console.log(require('/opt/matterbridge-package.json').dependencies.matterbridge)")" \
    && npm install --global --prefix /opt/matterbridge --omit=dev "matterbridge@${matterbridge_version}" \
    && mkdir -p node_modules \
    && ln -s /opt/matterbridge/lib/node_modules/matterbridge node_modules/matterbridge \
    && npm run build \
    && mkdir -p /opt/plugin/apps/frontend \
    && echo '{"name": "frontend", "version": "1.0.0"}' > /opt/plugin/apps/frontend/package.json

COPY --chown=matterbridge:matterbridge docker/requirements.txt /opt/logger-requirements.txt

RUN uv venv --python 3.14 /opt/logger-venv \
    && uv pip install --python /opt/logger-venv/bin/python --no-cache --requirement /opt/logger-requirements.txt

EXPOSE 5540/udp 5353/udp
VOLUME ["/data"]
ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
