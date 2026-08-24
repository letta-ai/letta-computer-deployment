# Letta computer deployment

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/letta-code-remote?utm_medium=integration&utm_source=template&utm_campaign=generic)

Run an always-on [computer](https://docs.letta.com/platform/computers/byom) for agents hosted in Letta Cloud. The container connects outward to Letta Cloud and appears in the computer picker in the Letta app and chat.letta.com.

## Docker Compose

```bash
cp .env.example .env
docker compose up --build -d
docker compose logs -f
```

If `LETTA_API_KEY` is unset, the logs print an OAuth authorization URL. Open it and approve the computer. The Compose configuration persists Letta settings and gives the computer a persistent `/workspace` volume.

No inbound port, reverse proxy, or domain is required.

## Configuration

- `ENV_NAME` controls the name shown in the computer picker.
- `LETTA_API_KEY` skips OAuth on plans that support API-key computer authentication.
- `LETTA_RESTORE_ENABLED_CHANNELS=1` restores configured channel adapters after restart.
- `LETTA_BASE_URL` points the computer at another Letta API deployment.
- `LETTA_SYSTEM_CRON_DIR` and `LETTA_SYSTEM_ROOT_CRONTAB` restore Unix cron files from persistent storage on boot. Their defaults are under `/root/.letta`.

Startup checks channel status and installs optional runtimes required by enabled
channels before restoring them. This keeps persisted Slack, Telegram, Discord,
and WhatsApp accounts usable after the base image is replaced.

Files stored directly in `/etc/cron.d` disappear when a container is replaced. Put persistent definitions under `/root/.letta/system-cron`, and put an optional root crontab at `/root/.letta/system-crontab/root`.

The Dockerfile pins a released `ghcr.io/letta-ai/letta-code` image. An hourly
GitHub workflow updates that pin after the matching npm and container releases
are both available, producing a commit that connected platforms can deploy.

To override the release for a one-off build:

```bash
docker build \
  --build-arg LETTA_CODE_IMAGE=ghcr.io/letta-ai/letta-code:0.30.21 \
  -t my-letta-computer .
```

See [Bring Your Own Machine](https://docs.letta.com/platform/computers/byom) for provider-specific deployment instructions, authentication, and verification.

## Container restarts

The startup script clears standalone-listener lock files before launching.
Those locks are runtime ownership records, not user state; retaining them on a
persistent volume can otherwise block a replacement container when its PID is
reused. Railway is configured with an always-restart policy so a transient
failure does not exhaust a finite retry budget and leave the computer offline.
Deployment overlap is disabled because two generations must not share one
computer identity or its persistent volume concurrently.
