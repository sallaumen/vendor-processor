defmodule Ports.AccountingIntegration do
  @moduledoc """
  Port interface for accounting system integrations.
  """
  @callback authenticate() :: {:ok, Req.Response.t()} | {:error, any()}
  @callback health_check() :: {:ok, Req.Response.t()} | {:error, any()}
  @callback list_all_vendors() :: {:ok, list(VendorProcessor.VendorData.t())} | {:error, any()}
  @callback upsert_vendor(vendor_data :: VendorProcessor.VendorData.t()) ::
              {:ok, Req.Response.t()} | {:error, any()}
  @callback delete_vendor(vendor_id :: String.t()) :: {:ok, Req.Response.t()} | {:error, any()}

  def resolve do
    Application.get_env(:vendor_processor, Ports.AccountingIntegration)[:adapter]
  end
end
