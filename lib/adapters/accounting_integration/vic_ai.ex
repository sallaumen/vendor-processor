defmodule Adapters.AccountingIntegration.VicAi do
  alias Ports.AccountingIntegration

  @behaviour AccountingIntegration
  @base_url "https://api.no.stage.vic.ai/v0"
  @client_id System.fetch_env!("VIC_AI_CLIENT_ID")
  @client_secret System.fetch_env!("VIC_AI_CLIENT_SECRET")

  @impl true
  def authenticate() do
    params =
      [
        method: :post,
        url: @base_url <> "/token",
        body:
          Jason.encode!(%{
            client_id: @client_id,
            client_secret: @client_secret
          }),
        headers: [
          {"content-type", "application/json"}
        ]
      ]

    extra_options = Application.get_env(:vendor_processor, __MODULE__)[:vic_ai_req_options]
    request = params ++ extra_options

    Req.request(request)
  end

  @impl true
  def health_check() do
    params = [base_url: @base_url <> "/healthCheck"]
    extra_options = Application.get_env(:vendor_processor, __MODULE__)[:vic_ai_req_options]
    authorization_headers = get_authentication_headers()
    request = params ++ extra_options ++ authorization_headers

    Req.request(request)
  end

  defp get_authentication_headers(),
    do: [headers: [{"Authorization", "MpPcTPACkmY5aRUmTxC5g4XNPM99b1ho1kUAeUunFbTRgbSm4WqwDPfLCKK93jxg"}]]
end
