import Config

config :vendor_processor, Adapters.AccountingIntegration.VicAi,
  vic_ai_req_options: [
    plug: {Req.Test, Adapters.AccountingIntegration.VicAi},
    receive_timeout: 1,
    retry_delay: 1,
    max_retries: 1
  ]
