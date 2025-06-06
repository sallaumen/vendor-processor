defmodule Adapters.AccountingIntegration.VicAiTest do
  use ExUnit.Case, async: true
  alias Adapters.AccountingIntegration.VicAi
  alias Plug.Conn
  alias Req.Response
  alias Req.Test
  alias Support.Factories.VendorDataFactory
  alias Support.Factories.Adapters.VicAiFactory

  @default_factory_updated_at ~N[2025-01-01 00:00:00]

  describe "authenticate/1" do
    test "when 200 response, should return {:ok, Req.Response} tuple with details" do
      Test.expect(VicAi, fn %{request_path: "/v0/token"} = conn ->
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
      Test.expect(VicAi, fn %{request_path: "/v0/token"} = conn ->
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
      Test.stub(VicAi, fn %{request_path: "/v0/token"} = conn ->
        Req.Test.transport_error(conn, :timeout)
      end)

      assert {:error, %Req.TransportError{__exception__: true, reason: :timeout}} =
               VicAi.authenticate()
    end
  end

  describe "health_check/1" do
    test "when 200 response, should return {:ok, Req.Response} tuple with details" do
      Test.expect(VicAi, fn %{request_path: "/v0/healthCheck"} = conn ->
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
      Test.expect(VicAi, fn %{request_path: "/v0/healthCheck"} = conn ->
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
      Test.stub(VicAi, fn %{request_path: "/v0/healthCheck"} = conn ->
        Req.Test.transport_error(conn, :timeout)
      end)

      assert {:error, %Req.TransportError{__exception__: true, reason: :timeout}} =
               VicAi.health_check()
    end
  end

  describe "list_all_vendors/1" do
    test "when 200 response when empty list, should return {:ok, []} tuple" do
      Test.expect(VicAi, fn %{request_path: "/v0/vendors"} = conn ->
        Test.json(conn, [])
      end)

      assert {:ok, []} == VicAi.list_all_vendors()
    end

    test "when 200 response when vendors exist, should return {:ok, list(VendorData.t())}" do
      vendor_data = VendorDataFactory.build(:generic, %{updated_at: @default_factory_updated_at})
      vendor_data_1_response = build_vendor_data_response(vendor_data)

      Test.expect(VicAi, fn %{request_path: "/v0/vendors"} = conn ->
        Test.json(conn, [vendor_data_1_response])
      end)

      assert {:ok, [vendor_data]} == VicAi.list_all_vendors()
    end

    test "when 200 response when multiple vendors exist, should return {:ok, list(VendorData.t())}" do
      vendor_data_1 = VendorDataFactory.build(:generic, %{updated_at: @default_factory_updated_at})
      vendor_data_2 = VendorDataFactory.build(:generic, %{updated_at: @default_factory_updated_at})
      vendor_data_1_response = build_vendor_data_response(vendor_data_1)
      vendor_data_2_response = build_vendor_data_response(vendor_data_2)

      Test.expect(VicAi, fn %{request_path: "/v0/vendors"} = conn ->
        Test.json(conn, [vendor_data_1_response, vendor_data_2_response])
      end)

      assert {:ok, [vendor_data_1, vendor_data_2]} == VicAi.list_all_vendors()
    end
  end

  describe "upsert_vendor/1" do
    test "when success on upsert, should return {:ok, VendorData.t()}" do
      vendor_data = VendorDataFactory.build(:generic, %{updated_at: @default_factory_updated_at})
      vendor_data_1_response = build_vendor_data_response(vendor_data)
      expected_request_path = "/v0/vendors/#{vendor_data.id}"

      Test.expect(VicAi, fn %{request_path: ^expected_request_path} = conn ->
        Test.json(conn, vendor_data_1_response)
      end)

      {:ok, vendor_data_response} = VicAi.upsert_vendor(vendor_data)
      assert vendor_data == vendor_data_response
    end

    test "when 422 response when multiple vendors exist, should return {:ok, Req.Response} vendor details" do
      vendor_data = VendorDataFactory.build(:generic)
      expected_request_path = "/v0/vendors/#{vendor_data.id}"

      Test.expect(VicAi, fn %{request_path: ^expected_request_path} = conn ->
        Conn.send_resp(conn, :unprocessable_entity, ~s|{"code": 422, "message": "externalUpdatedAt: can't be blank"}|)
      end)

      assert {
               :error,
               {:unmapped_case,
                {:ok,
                 %Req.Response{status: 422, body: "{\"code\": 422, \"message\": \"externalUpdatedAt: can't be blank\"}"}}}
             } =
               VicAi.upsert_vendor(vendor_data)
    end
  end

  describe "delete_vendor/1" do
    # TODO: incomplete tests
    test "when 200 response, should consider data as deleted" do
    end

    test "when non 200 response, should consider data as deleted" do
    end
  end

  defp build_vendor_data_response(vendor_data) do
    VicAiFactory.build(:vendor_response, %{
      "externalId" => vendor_data.id,
      "countryCode" => vendor_data.country,
      "name" => vendor_data.name,
      "email" => vendor_data.email,
      "phone" => vendor_data.phone,
      "addressCity" => vendor_data.city,
      "addressPostalCode" => vendor_data.zip,
      "addressState" => vendor_data.state,
      "addressStreet" => vendor_data.address,
      "currency" => vendor_data.currency
    })
  end
end
