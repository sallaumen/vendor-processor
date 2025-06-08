defmodule VendorProcessor.FileImport.CSVProcessorTest do
  use ExUnit.Case, async: true
  alias VendorProcessor.FileImport.CSVProcessor
  alias VendorProcessor.VendorData

  import ExUnit.CaptureLog

  @valid_csv """
  "id","name","country","state","city","address","zip","email","phone","currency"
  "4126494871","Leuschke, Sanford and Weber","US","MA","Delphine","53735 DuBuque Loaf","85667","virginie1945@kilback.info","376-888-6149","USD"
  "1945790520","Mante, Wiegand and Kutch","US","WY","Lake Lillian","44 Lehner Bridge","31054","will2028@pollich.org","(424) 949-6807","USD"
  """

  @invalid_csv_line_err_case """
  "id","name","country","state","city","address","zip","email","phone","currency"
  "1945790520","Mante, Wiegand and Kutch","US","WY","Lake Lillian","44 Lehner Bridge","31054","will2028@pollich.org","(424) 949-6807","USD"
  INVALID LINE WITHOUT CSV FORMAT
  """

  @invalid_csv_line_nil_value_case """
  "id","name","country","state","city","address","zip"
  "1945790520",nil,"US","WY","Lake Lillian","44 Lehner Bridge","31054"
  """

  describe "process_csv_stream/1" do
    test "when valid CSV stream provided, should build VendorData for each line" do
      result =
        @valid_csv
        |> stream_from_string()
        |> CSVProcessor.process_csv_stream()

      assert length(result) == 2
      assert result == get_expected_valid_stream_process()
    end

    test "when invalid line inside CSV, should filter invalid lines and process remaining" do
      log =
        capture_log(fn ->
          result =
            @invalid_csv_line_err_case
            |> stream_from_string()
            |> CSVProcessor.process_csv_stream()

          assert length(result) == 1
        end)

      assert log =~ "[error] Vendor data of id `INVALID LINE WITHOUT CSV FORMAT` contains null fields:"
    end

    test "when line contains nil values, should ignore line and log error" do
      log =
        capture_log(fn ->
          result =
            @invalid_csv_line_nil_value_case
            |> stream_from_string()
            |> CSVProcessor.process_csv_stream()

          assert Enum.empty?(result)
        end)

      assert log =~
               "[error] Vendor data of id `1945790520` contains null fields: " <>
                 "%{id: \"1945790520\", name: \"nil\", state: \"WY\""
    end
  end

  defp stream_from_string(str) do
    str
    |> String.split("\n", trim: true)
    |> Stream.map(&(&1 <> "\n"))
  end

  defp get_expected_valid_stream_process do
    [
      %VendorData{
        id: "4126494871",
        country: "US",
        name: "Leuschke, Sanford and Weber",
        email: "virginie1945@kilback.info",
        phone: "376-888-6149",
        address: "53735 DuBuque Loaf",
        city: "Delphine",
        state: "MA",
        zip: "85667",
        currency: "USD"
      },
      %VendorData{
        id: "1945790520",
        country: "US",
        name: "Mante, Wiegand and Kutch",
        email: "will2028@pollich.org",
        phone: "(424) 949-6807",
        address: "44 Lehner Bridge",
        city: "Lake Lillian",
        state: "WY",
        zip: "31054",
        currency: "USD"
      }
    ]
  end
end
