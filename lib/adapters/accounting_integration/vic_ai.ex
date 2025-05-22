defmodule Adapters.AccountingIntegration.VicAi do
  @moduledoc """
  Vic AI accounting REST API integration.

  Note: VicAi API has throttle which currently is still not being considered during the implementation.
  Future improvement: Create global consecutive request counter and reject requests above global API Key limit.
  """
  alias Adapters.AccountingIntegration.VicAiTokenManager
  alias Ports.AccountingIntegration
  alias VendorProcessor.VendorData

  @behaviour AccountingIntegration
  @base_url "https://api.no.stage.vic.ai/v0"
  @client_id System.fetch_env!("VIC_AI_CLIENT_ID")
  @client_secret System.fetch_env!("VIC_AI_CLIENT_SECRET")

  @success_statuses [200, 201]

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
        headers: [{"content-type", "application/json"}]
      ]

    extra_options = Application.get_env(:vendor_processor, __MODULE__)[:vic_ai_req_options]
    request = params ++ extra_options

    Req.request(request)
  end

  @impl true
  def health_check() do
    params = [method: :get, base_url: @base_url <> "/healthCheck"]
    extra_options = Application.get_env(:vendor_processor, __MODULE__)[:vic_ai_req_options]
    authorization_headers = get_authentication_headers()
    request = params ++ extra_options ++ authorization_headers

    Req.request(request)
  end

  @impl true
  def list_all_vendors() do
    params = [method: :get, base_url: @base_url <> "/vendors"]
    extra_options = Application.get_env(:vendor_processor, __MODULE__)[:vic_ai_req_options]
    authorization_headers = get_authentication_headers()
    request = params ++ extra_options ++ authorization_headers

    request
    |> Req.request()
    |> parse_vendor_list_response()
  end

  @impl true
  def upsert_vendor(%VendorData{} = vendor_data) do
    params = [
      method: :put,
      base_url: @base_url <> "/vendors/#{vendor_data.id}",
      body: build_upsert_vendor_body(vendor_data),
      headers: [{"content-type", "application/json"}]
    ]

    extra_options = Application.get_env(:vendor_processor, __MODULE__)[:vic_ai_req_options]
    authorization_headers = get_authentication_headers()
    request = params ++ extra_options ++ authorization_headers

    request
    |> Req.request()
    |> parse_vendor_single_entry_response()
  end

  @impl true
  def delete_vendor(vendor_id) do
    params = [method: :delete, base_url: @base_url <> "/vendors/#{vendor_id}"]
    extra_options = Application.get_env(:vendor_processor, __MODULE__)[:vic_ai_req_options]
    authorization_headers = get_authentication_headers()
    request = params ++ extra_options ++ authorization_headers

    Req.request(request)
  end

  defp get_authentication_headers(),
    do: [headers: [{"Authorization", VicAiTokenManager.get_token()}]]

  defp parse_vendor_list_response({:ok, %Req.Response{status: status} = response}) when status in @success_statuses do
    vendor_data =
      Enum.map(response.body, &vendor_response_to_vendor_data/1)

    {:ok, vendor_data}
  end

  defp parse_vendor_list_response({:error, _} = error), do: error
  defp parse_vendor_list_response(unmapped_case), do: {:error, {:unmapped_case, unmapped_case}}

  defp parse_vendor_single_entry_response({:ok, %Req.Response{status: status} = response})
       when status in @success_statuses do
    {:ok, vendor_response_to_vendor_data(response.body)}
  end

  defp parse_vendor_single_entry_response({:error, _} = error), do: error
  defp parse_vendor_single_entry_response(unmapped_case), do: {:error, {:unmapped_case, unmapped_case}}

  defp vendor_response_to_vendor_data(vendor_raw_data) do
    %VendorData{
      id: vendor_raw_data["externalId"],
      name: vendor_raw_data["name"],
      email: vendor_raw_data["email"],
      phone: vendor_raw_data["phone"],
      city: vendor_raw_data["addressCity"],
      zip: vendor_raw_data["addressPostalCode"],
      country: vendor_raw_data["countryCode"],
      state: vendor_raw_data["addressState"],
      address: vendor_raw_data["addressStreet"],
      currency: vendor_raw_data["currency"],
      updated_at: NaiveDateTime.from_iso8601!(vendor_raw_data["externalUpdatedAt"])
    }
  end

  defp build_upsert_vendor_body(vendor_data) do
    %{
      "id" => vendor_data.id,
      "countryCode" => vendor_data.country,
      "name" => vendor_data.name,
      "email" => vendor_data.email,
      "phone" => vendor_data.phone,
      "addressCity" => vendor_data.city,
      "addressPostalCode" => vendor_data.zip,
      "addressState" => vendor_data.state,
      "addressStreet" => vendor_data.address,
      "currency" => vendor_data.currency,
      "externalUpdatedAt" => NaiveDateTime.utc_now() |> NaiveDateTime.to_string()
    }
    |> Jason.encode!()
  end
end
