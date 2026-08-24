#!/bin/sh
set -eu

# Listener locks live on the persistent Letta volume. A replaced container
# reuses PID 1, which can make the previous container's lock look live. This
# entrypoint is PID 1 and owns the container's only listener, so a valid manual
# lock naming PID 1 can only belong to the previous container generation.
listener_lock_dir="${HOME:-/root}/.letta/listeners"
if [ -d "$listener_lock_dir" ]; then
  for listener_lock in "$listener_lock_dir"/manual-*.lock; do
    [ -f "$listener_lock" ] || continue
    if jq -e '
      .version == 1 and
      .pid == 1 and
      (.ownerToken | type == "string" and length > 0) and
      (.acquiredAt | type == "string" and length > 0) and
      (.scopeHash | type == "string" and length > 0)
    ' "$listener_lock" >/dev/null 2>&1; then
      rm -f "$listener_lock" "$listener_lock".recover.*
    fi
  done
fi

# Letta Code 0.30.29 only applies --install-channel-runtimes to channels named
# explicitly with --channels, not channels discovered by restore-on-start.
# Install just the enabled missing runtimes before the gateway is launched.
channel_status_file="$(mktemp)"
trap 'rm -f "$channel_status_file"' EXIT HUP INT TERM
letta channels status > "$channel_status_file"
for channel in $(jq -r '
  to_entries[] |
  select(.value.enabled == true and .value.runtimeInstalled != true) |
  .key
' "$channel_status_file"); do
  letta channels install "$channel"
done
rm -f "$channel_status_file"
trap - EXIT HUP INT TERM

exec letta server \
  --env-name "${ENV_NAME:-cloud}" \
  --debug
