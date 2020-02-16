FROM debian:latest

MAINTAINER Logan V. <logan2211@gmail.com>

ENV TINI_VERSION v0.18.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini
ENTRYPOINT ["/tini", "--"]

COPY --from=lachlanevenson/k8s-kubectl:latest /usr/local/bin/kubectl /usr/local/bin/kubectl

RUN apt-get update && \
    apt-get install -y certbot jq python3-minimal && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /app/

CMD ["/app/entrypoint.sh"]
