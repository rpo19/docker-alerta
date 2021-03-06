FROM python:3.6-alpine

LABEL org.label-schema.build-date=${BUILD_DATE} \
      org.label-schema.vcs-url="https://github.com/rpo19/docker-alerta" \
      org.label-schema.vcs-ref=${VCS_REF} \
      org.label-schema.version=${VERSION} \
      org.label-schema.schema-version="1.0.0-rc.1"

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

ENV PATH ${PATH}:/venv/bin
ENV ALERTA_SVR_CONF_FILE /app/alertad.conf
ENV ALERTA_CONF_FILE     /app/alerta.conf
ENV ALERTA_WEB_CONF_FILE /web/config.json
ENV BASE_URL             /api
ENV INSTALL_PLUGINS      ""
ENV PYTHONUNBUFFERED     1
ENV HEARTBEAT_SEVERITY major

RUN apk update
RUN apk add --no-cache git libffi-dev nginx wget bash supervisor postgresql-dev gettext
RUN apk add --virtual build-dependencies python-dev build-base

RUN pip install --no-cache-dir virtualenv \
 && virtualenv --python=python3 /venv \
 && /venv/bin/pip install uwsgi alerta alerta-server==${VERSION}

RUN wget -q -O - "https://github.com/alerta/angular-alerta-webui/archive/v${VERSION}.tar.gz" |  tar xzf - -C /tmp/  \
 && mv /tmp/angular-alerta-webui-${VERSION}/app /web \
 && mv /web/config.json /web/config.json.orig \
 && rm -fr /tmp/angular-alerta-webui-${VERSION}

COPY slash/ /

RUN chgrp -R 0 /app /venv /web \
 && chmod -R g=u /app /venv /web \
 && adduser -S -h /app -u 1001 -G root alerta

USER 1001
EXPOSE 8080

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["supervisord", "-c", "/app/supervisord.conf"]
