ARG LETTA_CODE_IMAGE=ghcr.io/letta-ai/letta-code:0.31.6
FROM ${LETTA_CODE_IMAGE}

COPY --chmod=755 start-computer.sh /usr/local/bin/start-letta-computer

ENV ENV_NAME=cloud \
    LETTA_RESTORE_ENABLED_CHANNELS=1

CMD ["/usr/local/bin/start-letta-computer"]
