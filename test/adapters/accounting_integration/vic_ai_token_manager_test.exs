defmodule Adapters.AccountingIntegration.VicAiTokenManagerTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog
  alias Adapters.AccountingIntegration.VicAiTokenManager

  setup do
    original_config = Application.get_env(:vendor_processor, VicAiTokenManager)

    on_exit(fn ->
      Application.put_env(:vendor_processor, VicAiTokenManager, original_config)
    end)

    %{original_config: original_config}
  end

  describe "get_token/0" do
    test "when called in test environment, should return current token" do
      token = VicAiTokenManager.get_token()
      assert is_binary(token)
      assert token == "test_fake_token"
    end
  end

  describe "handle_info/2" do
    test "when refresh message sent, should handle gracefully and keep process alive" do
      pid = get_token_manager_pid()
      assert pid != nil

      send_refresh_and_wait(pid)

      assert Process.alive?(pid)

      token = VicAiTokenManager.get_token()
      assert is_binary(token)
    end

    test "when configured authentication function provided, should use it for token refresh" do
      custom_token = "custom_test_token"
      original_fn = Application.get_env(:vendor_processor, VicAiTokenManager)[:authentication_fn]

      mock_auth_fn = fn -> {:ok, %{body: %{"access_token" => custom_token}}} end
      update_auth_function(mock_auth_fn)

      pid = get_token_manager_pid()
      send_refresh_and_wait(pid)

      token = VicAiTokenManager.get_token()
      assert token == custom_token

      update_auth_function(original_fn)
    end

    test "when authentication function fails, should handle gracefully and log error" do
      original_fn = Application.get_env(:vendor_processor, VicAiTokenManager)[:authentication_fn]

      mock_auth_fn = fn -> {:error, "authentication failed"} end
      update_auth_function(mock_auth_fn)

      log_output =
        capture_log(fn ->
          pid = get_token_manager_pid()
          send_refresh_and_wait(pid)
        end)

      assert log_output =~ "Failed to update VicAi API token"

      update_auth_function(original_fn)
    end

    test "when multiple simultaneous calls made, should handle concurrent access safely" do
      tasks =
        for _ <- 1..10 do
          Task.async(fn -> VicAiTokenManager.get_token() end)
        end

      results = Enum.map(tasks, &Task.await/1)

      assert Enum.all?(results, &is_binary/1)
      assert length(results) == 10
    end
  end

  defp get_token_manager_pid, do: Process.whereis(VicAiTokenManager)

  defp send_refresh_and_wait(pid) do
    send(pid, :refresh_token)
    :timer.sleep(10)
  end

  defp update_auth_function(auth_fn) do
    Application.put_env(:vendor_processor, VicAiTokenManager, authentication_fn: auth_fn)
  end
end
