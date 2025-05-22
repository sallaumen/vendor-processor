import Config

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :trace_id, :mfa]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [
    :line,
    :crash_reason,
    :pid
  ]

import_config "#{config_env()}.exs"
