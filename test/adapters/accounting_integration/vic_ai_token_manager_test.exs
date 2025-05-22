defmodule Adapters.AccountingIntegration.VicAiTokenManagerTest do
  use ExUnit.Case, async: true
  alias Adapters.AccountingIntegration.VicAiTokenManager

  describe "get_token/0" do
    test "when test env, should return config's fake token" do
      assert VicAiTokenManager.get_token() == "test_fake_token"
    end
  end
end
