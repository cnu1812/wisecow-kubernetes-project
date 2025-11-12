FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/usr/games:${PATH}"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        fortune-mod cowsay netcat-openbsd ca-certificates && \
    ln -sf /usr/games/fortune /usr/local/bin/fortune || true && \
    ln -sf /usr/games/cowsay  /usr/local/bin/cowsay  || true && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY fortunes/wisecow /usr/share/games/fortunes/wisecow
# To create the fortune index file (.dat)
RUN strfile /usr/share/games/fortunes/wisecow || true

COPY wisecow.sh /app/wisecow.sh
RUN chmod +x /app/wisecow.sh

EXPOSE 4499

RUN useradd -m -u 1001 appuser && chown -R appuser:appuser /app
USER appuser

CMD ["/app/wisecow.sh"]
