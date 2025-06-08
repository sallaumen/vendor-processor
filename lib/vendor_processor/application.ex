defmodule VendorProcessor.Application do
  @moduledoc """
  OTP Application module for VendorProcessor.
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Adapters.AccountingIntegration.VicAiTokenManager
    ]

    opts = [strategy: :one_for_one, name: VendorProcessor.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
