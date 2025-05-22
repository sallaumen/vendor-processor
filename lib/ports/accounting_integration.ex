defmodule Ports.AccountingIntegration do
  @callback authenticate() :: {:ok, Req.Response.t()} | {:error, any()}
  @callback health_check() :: {:ok, Req.Response.t()} | {:error, any()}

  def resolve do
    Application.get_env(:vendor_processor, Ports.AccountingIntegration)[:adapter]
  end
end
