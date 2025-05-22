defmodule VendorProcessor.FileImport.CSVProcessor do
  @moduledoc """
  A module to process CSV files containing vendor data.

  Invalid csv files will have their rows filtered out.

  ## Example usage

      iex> File.stream!("/path/to/vendors.csv") |> VendorProcessor.FileImport.CSVProcessor.process_csv_stream
      [%VendorData{id: "1", name: "Vendor A", email: ...]

  ## CSV Example
      "id","name","country","state",...
      "4126494871","Leuschke, Sanford and Weber","US","MA",...
  """
  require Logger
  alias VendorProcessor.VendorData

  @spec process_csv_stream(String.t()) :: list(VendorData.t())
  def process_csv_stream(data_stream) do
    data_stream
    |> CSV.decode(headers: true)
    |> Enum.filter(&filter_valid_row/1)
    |> Enum.map(&build_vendor_data/1)
    |> Enum.filter(&no_nil_fields_filter/1)
  end

  defp filter_valid_row({:ok, _}), do: true

  defp filter_valid_row(err) do
    Logger.error("Failed to decode CSV: #{inspect(err)}")
    false
  end

  defp no_nil_fields_filter(vendor_data) do
    vendor_data = Map.drop(vendor_data, [:updated_at])

    if Enum.any?(Map.values(vendor_data), &is_nil/1) do
      Logger.error("Vendor data of id `#{vendor_data.id}` contains null fields: #{inspect(vendor_data)}")
      false
    else
      true
    end
  end

  defp build_vendor_data({:ok, row}) do
    %VendorData{
      id: row["id"],
      country: row["country"],
      name: row["name"],
      email: row["email"],
      phone: row["phone"],
      address: row["address"],
      city: row["city"],
      state: row["state"],
      zip: row["zip"],
      currency: row["currency"]
    }
  end
end
