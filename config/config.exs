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

config :vendor_processor, Ports.AccountingIntegration, adapter: Adapters.AccountingIntegration.VicAi

config :vendor_processor, Adapters.AccountingIntegration.VicAi, vic_ai_req_options: []

import_config "#{config_env()}.exs"
