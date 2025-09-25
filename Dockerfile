FROM frappe/build:v15 as base

USER root

# Install cron, bzip2, gnupg2, supervisor, dll.
RUN apt-get update \
    && apt-get install -y cron && which cron && \
    rm -rf /etc/cron.*/* \
    && apt-get install -y bzip2 \
    && apt-get install -y gnupg2 \
    && apt-get install -y rsync \
    && apt-get install -y supervisor \
    && chown -R frappe:frappe /home/frappe

FROM base AS frappe

USER frappe

COPY motd.txt /etc/motd_custom.txt

ARG FRAPPE_BRANCH=version-15
ARG FRAPPE_PATH=https://github.com/frappe/frappe
RUN bench init \
  --frappe-branch=${FRAPPE_BRANCH} \
  --frappe-path=${FRAPPE_PATH} \
  --no-procfile \
  --no-backups \
  --skip-redis-config-generation \
  --verbose \
  /home/frappe/frappe-bench && \
  cd /home/frappe/frappe-bench && \
  echo "{}" > sites/common_site_config.json

COPY prepare.sh /usr/local/bin/prepare.sh
COPY start-backend.sh /usr/local/bin/start-backend.sh

USER root

RUN echo "cat /etc/motd_custom.txt" >> ~/.bashrc \
    && echo "cat /etc/motd_custom.txt" >> /home/frappe/.bashrc && chown -R frappe:frappe /home/frappe/.bashrc \
    && chmod +x /usr/local/bin/prepare.sh \
    && chmod +x /usr/local/bin/start-backend.sh

WORKDIR /home/frappe/frappe-bench

VOLUME [ \
  "/home/frappe/frappe-bench/sites", \
  "/home/frappe/frappe-bench/sites/assets", \
  "/home/frappe/frappe-bench/logs" \
]

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 22
EXPOSE 3000
EXPOSE 8000
EXPOSE 8080

CMD ["supervisord", "-n"]
