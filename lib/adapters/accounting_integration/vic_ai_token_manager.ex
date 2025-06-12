defmodule Adapters.AccountingIntegration.VicAiTokenManager do
  @moduledoc """
  This module manages the VicAi API token lifecycle. It retrieves a new token
  when the old one is about to expire and provides a way to access the current
  """
  use GenServer
  require Logger

  @refresh_interval_ms 300_000

  @spec get_token() :: String.t() | nil
  def get_token do
    GenServer.call(__MODULE__, :get_token)
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    state = %{token: request_new_token(), refresh_interval: @refresh_interval_ms}
    schedule_refresh(state.refresh_interval)

    {:ok, state}
  end

  @impl true
  def handle_call(:get_token, _from, state) do
    {:reply, state.token, state}
  end

  @impl true
  def handle_info(:refresh_token, state) do
    %{token: old_token} = state
    new_token = request_new_token() || old_token

    schedule_refresh(state.refresh_interval)
    {:noreply, %{state | token: new_token}}
  end

  defp schedule_refresh(refresh_interval) do
    Process.send_after(self(), :refresh_token, refresh_interval)
  end

  defp request_new_token() do
    case do_authenticate() do
      {:ok, %{body: %{"access_token" => token}}} ->
        token

      err ->
        Logger.critical("Failed to update VicAi API token. Please check before old one expires. Details: #{inspect(err)}")
        nil
    end
  end

  defp do_authenticate do
    authentication_fn = Application.get_env(:vendor_processor, __MODULE__)[:authentication_fn]
    authentication_fn.()
  end
end
