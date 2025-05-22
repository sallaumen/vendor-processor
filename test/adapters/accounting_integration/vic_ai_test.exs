defmodule Adapters.AccountingIntegration.VicAiTest do
  use ExUnit.Case, async: true
  alias Adapters.AccountingIntegration.VicAi
  alias Req.Response
  alias Plug.Conn
  alias Req.Test

  describe "authenticate/1" do
    test "when 2xx response, should return {:ok, Req.Response} tuple with details" do
      Test.stub(VicAi, fn conn ->
        Test.json(conn, %{
          "access_token" => "example token",
          "expires_in" => 3600,
          "token_type" => "Bearer"
        })
      end)

      assert {
               :ok,
               %Response{
                 body: %{
                   "access_token" => "example token",
                   "expires_in" => 3600,
                   "token_type" => "Bearer"
                 },
                 status: 200
               }
             } =
               VicAi.authenticate()
    end

    test "when invalid credentials given, should return {:ok, Req.Response} tuple with details 400 status" do
      Test.stub(VicAi, fn conn ->
        Conn.send_resp(conn, :bad_request, ~s|{"code": 400, "message": "invalid credentials"}|)
      end)

      assert {
               :ok,
               %Response{
                 body: "{\"code\": 400, \"message\": \"invalid credentials\"}",
                 status: 400
               }
             } =
               VicAi.authenticate()
    end

    test "when connection error, should return {:err, error_detail} tuple" do
      Test.stub(VicAi, fn conn ->
        Req.Test.transport_error(conn, :timeout)
      end)

      assert {:error, %Req.TransportError{__exception__: true, reason: :timeout}} =
               VicAi.authenticate()
    end
  end

  describe "health_check/1" do
    test "when 2xx response, should return {:ok, Req.Response} tuple with details" do
      Test.stub(VicAi, fn conn ->
        Test.json(conn, %{"company" => "test", "status" => "PASS", "version" => "1.0"})
      end)

      assert {
               :ok,
               %Response{
                 body: %{"company" => "test", "status" => "PASS", "version" => "1.0"},
                 status: 200
               }
             } =
               VicAi.health_check()
    end

    test "when non 404 response, should return {:ok, Req.Response} tuple with details" do
      Test.stub(VicAi, fn conn ->
        Conn.send_resp(conn, :not_found, ~s|{"code": 404, "message": "not found"}|)
      end)

      assert {
               :ok,
               %Response{
                 body: "{\"code\": 404, \"message\": \"not found\"}",
                 status: 404
               }
             } =
               VicAi.health_check()
    end

    test "when connection error, should return {:err, error_detail} tuple" do
      Test.stub(VicAi, fn conn ->
        Req.Test.transport_error(conn, :timeout)
      end)

      assert {:error, %Req.TransportError{__exception__: true, reason: :timeout}} =
               VicAi.health_check()
    end
  end
end
