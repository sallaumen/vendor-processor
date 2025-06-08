defmodule VendorProcessor.FileImport.CSVImporterTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog
  alias VendorProcessor.FileImport.CSVImporter
  alias Support.Factories.VendorDataFactory
  alias Support.Factories.Adapters.VicAiFactory
  alias Adapters.AccountingIntegration.VicAi
  alias Req.Test

  @test_csv_content """
  id,name,email,phone,address,city,state,zip,country,currency,updated_at
  vendor1,Test Vendor 1,test1@example.com,123-456-7890,123 Main St,Test City,Test State,12345,US,USD,2025-01-01 10:00:00
  vendor2,Test Vendor 2,test2@example.com,987-654-3210,456 Oak Ave,Another City,Another State,67890,CA,CAD,2025-01-01 11:00:00
  """

  @invalid_csv_content """
  id,name,email,phone,city,state,zip,country,currency,updated_at
  vendor1,Test Vendor 1,test1@example.com,123-456-7890,Test City,Test State,12345,US,USD,2025-01-01 10:00:00
  vendor2,Test Vendor 2,test2@example.com,987-654-3210,Another City,Another State,67890,CA,CAD,2025-01-01 11:00:00
  """

  @empty_csv_content """
  id,name,email,phone,address,city,state,zip,country,currency,updated_at
  """

  setup do
    original_adapter = Application.get_env(:vendor_processor, Ports.AccountingIntegration)[:adapter]
    Application.put_env(:vendor_processor, Ports.AccountingIntegration, adapter: VicAi)

    test_csv_path = "/tmp/test_vendors.csv"
    invalid_csv_path = "/tmp/invalid_vendors.csv"
    empty_csv_path = "/tmp/empty_vendors.csv"
    nonexistent_path = "/tmp/nonexistent.csv"

    File.write!(test_csv_path, @test_csv_content)
    File.write!(invalid_csv_path, @invalid_csv_content)
    File.write!(empty_csv_path, @empty_csv_content)

    on_exit(fn ->
      Application.put_env(:vendor_processor, Ports.AccountingIntegration, adapter: original_adapter)
      File.rm(test_csv_path)
      File.rm(invalid_csv_path)
      File.rm(empty_csv_path)
    end)

    %{
      test_csv_path: test_csv_path,
      invalid_csv_path: invalid_csv_path,
      empty_csv_path: empty_csv_path,
      nonexistent_path: nonexistent_path
    }
  end

  describe "import_csv/1" do
    test "when valid CSV file given, should import successfully", %{test_csv_path: test_csv_path} do
      setup_successful_import_mocks()

      log_output =
        capture_log(fn ->
          assert :ok = CSVImporter.import_csv(test_csv_path)
        end)

      assert log_output =~ "CSV import completed successfully"
    end

    test "when file not found, should raise File.Error", %{nonexistent_path: nonexistent_path} do
      assert_raise File.Error, ~r/could not stream/, fn ->
        CSVImporter.import_csv(nonexistent_path)
      end
    end

    test "when invalid CSV data given, should handle gracefully and log errors", %{invalid_csv_path: invalid_csv_path} do
      setup_basic_mocks()

      log_output =
        capture_log(fn ->
          assert :ok = CSVImporter.import_csv(invalid_csv_path)
        end)

      assert log_output =~ "Vendor data of id `vendor1` contains null fields"
      assert log_output =~ "Vendor data of id `vendor2` contains null fields"
      assert log_output =~ "CSV import completed successfully"
    end

    test "when empty CSV file given, should complete successfully", %{empty_csv_path: empty_csv_path} do
      setup_basic_mocks()

      log_output =
        capture_log(fn ->
          assert :ok = CSVImporter.import_csv(empty_csv_path)
        end)

      assert log_output =~ "CSV import completed successfully"
    end

    test "when upsert failures occur, should log errors and continue", %{test_csv_path: test_csv_path} do
      setup_upsert_failure_mocks()

      log_output =
        capture_log(fn ->
          assert :ok = CSVImporter.import_csv(test_csv_path)
        end)

      assert log_output =~ "Failed to upsert vendor data"
      assert log_output =~ "CSV import from file path"
      assert log_output =~ "failed"
    end

    test "when older vendors exist, should delete them after successful import", %{test_csv_path: test_csv_path} do
      old_vendor = build_old_vendor()
      setup_vendor_deletion_mocks(old_vendor)

      log_output =
        capture_log(fn ->
          assert :ok = CSVImporter.import_csv(test_csv_path)
        end)

      assert log_output =~ "Deleting vendor"
      assert log_output =~ "since it is older than"
      assert log_output =~ "CSV import completed successfully"
    end

    test "when delete_vendor failures occur, should handle gracefully", %{test_csv_path: test_csv_path} do
      old_vendor = build_old_vendor()
      setup_vendor_deletion_failure_mocks(old_vendor)

      log_output =
        capture_log(fn ->
          assert :ok = CSVImporter.import_csv(test_csv_path)
        end)

      assert log_output =~ "CSV import completed successfully"
    end

    test "when importing, should wait 1 second to avoid timing precision errors", %{test_csv_path: test_csv_path} do
      setup_successful_import_mocks()

      start_time = System.monotonic_time(:millisecond)

      capture_log(fn ->
        CSVImporter.import_csv(test_csv_path)
      end)

      end_time = System.monotonic_time(:millisecond)
      elapsed = end_time - start_time

      assert elapsed >= 1000
    end
  end

  defp setup_basic_mocks do
    Test.stub(VicAi, fn
      %{request_path: "/v0/token", method: "POST"} = conn ->
        Test.json(conn, %{"access_token" => "test_token", "expires_in" => 3600, "token_type" => "Bearer"})

      %{request_path: "/v0/vendors", method: "GET"} = conn ->
        Test.json(conn, [])
    end)
  end

  defp setup_successful_import_mocks do
    Test.stub(VicAi, fn
      %{request_path: "/v0/token", method: "POST"} = conn ->
        mock_authentication_response(conn)

      %{request_path: "/v0/vendors", method: "GET"} = conn ->
        Test.json(conn, [])

      %{request_path: "/v0/vendors/vendor1", method: "PUT"} = conn ->
        mock_vendor1_response(conn)

      %{request_path: "/v0/vendors/vendor2", method: "PUT"} = conn ->
        mock_vendor2_response(conn)
    end)
  end

  defp setup_upsert_failure_mocks do
    Test.stub(VicAi, fn
      %{request_path: "/v0/token", method: "POST"} = conn ->
        mock_authentication_response(conn)

      %{request_path: "/v0/vendors", method: "GET"} = conn ->
        Test.json(conn, [])

      %{request_path: "/v0/vendors/vendor1", method: "PUT"} = conn ->
        mock_upsert_error_response(conn)

      %{request_path: "/v0/vendors/vendor2", method: "PUT"} = conn ->
        mock_upsert_error_response(conn)
    end)
  end

  defp setup_vendor_deletion_mocks(old_vendor) do
    old_vendor_response = build_vendor_response(old_vendor, "2020-01-01 00:00:00")

    Test.stub(VicAi, fn
      %{request_path: "/v0/token", method: "POST"} = conn ->
        mock_authentication_response(conn)

      %{request_path: "/v0/vendors", method: "GET"} = conn ->
        Test.json(conn, [old_vendor_response])

      %{request_path: "/v0/vendors/vendor1", method: "PUT"} = conn ->
        mock_vendor1_response(conn)

      %{request_path: "/v0/vendors/vendor2", method: "PUT"} = conn ->
        mock_vendor2_response(conn)

      %{request_path: "/v0/vendors/old_vendor", method: "DELETE"} = conn ->
        Test.json(conn, %{"status" => "deleted"})
    end)
  end

  defp setup_vendor_deletion_failure_mocks(old_vendor) do
    old_vendor_response = build_vendor_response(old_vendor, "2020-01-01 00:00:00")

    Test.stub(VicAi, fn
      %{request_path: "/v0/token", method: "POST"} = conn ->
        mock_authentication_response(conn)

      %{request_path: "/v0/vendors", method: "GET"} = conn ->
        Test.json(conn, [old_vendor_response])

      %{request_path: "/v0/vendors/vendor1", method: "PUT"} = conn ->
        mock_vendor1_response(conn)

      %{request_path: "/v0/vendors/vendor2", method: "PUT"} = conn ->
        mock_vendor2_response(conn)

      %{request_path: "/v0/vendors/old_vendor", method: "DELETE"} = conn ->
        Plug.Conn.send_resp(conn, :not_found, ~s|{"code": 404, "message": "vendor not found"}|)
    end)
  end

  defp build_old_vendor do
    VendorDataFactory.build(:generic, %{
      id: "old_vendor",
      updated_at: ~N[2020-01-01 00:00:00]
    })
  end

  defp build_vendor_response(vendor, external_updated_at) do
    VicAiFactory.build(:vendor_response, %{
      "externalId" => vendor.id,
      "name" => vendor.name,
      "email" => vendor.email,
      "phone" => vendor.phone,
      "addressStreet" => vendor.address,
      "addressCity" => vendor.city,
      "addressState" => vendor.state,
      "addressPostalCode" => vendor.zip,
      "countryCode" => vendor.country,
      "currency" => vendor.currency,
      "externalUpdatedAt" => external_updated_at
    })
  end

  defp mock_authentication_response(conn) do
    Test.json(conn, %{"access_token" => "test_token", "expires_in" => 3600, "token_type" => "Bearer"})
  end

  defp mock_vendor1_response(conn) do
    vendor_response =
      VicAiFactory.build(:vendor_response, %{
        "externalId" => "vendor1",
        "name" => "Test Vendor 1",
        "email" => "test1@example.com",
        "phone" => "123-456-7890",
        "addressStreet" => "123 Main St",
        "addressCity" => "Test City",
        "addressState" => "Test State",
        "addressPostalCode" => "12345",
        "countryCode" => "US",
        "currency" => "USD"
      })

    Test.json(conn, vendor_response)
  end

  defp mock_vendor2_response(conn) do
    vendor_response =
      VicAiFactory.build(:vendor_response, %{
        "externalId" => "vendor2",
        "name" => "Test Vendor 2",
        "email" => "test2@example.com",
        "phone" => "987-654-3210",
        "addressStreet" => "456 Oak Ave",
        "addressCity" => "Another City",
        "addressState" => "Another State",
        "addressPostalCode" => "67890",
        "countryCode" => "CA",
        "currency" => "CAD"
      })

    Test.json(conn, vendor_response)
  end

  defp mock_upsert_error_response(conn) do
    Plug.Conn.send_resp(conn, :unprocessable_entity, ~s|{"code": 422, "message": "upsert failed"}|)
  end
end
