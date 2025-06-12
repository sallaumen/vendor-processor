defmodule VendorProcessor.FileImport.CSVImporter do
  @moduledoc """
  A module that imports vendor data from a CSV file.
  It processes the CSV file, upserts the vendor data into the database,
  and deletes all vendors that are older then the import_csv execution time.

  Call Example: VendorProcessor.FileImport.CSVImporter.import_csv("path/file.csv")

  """
  require Logger
  alias VendorProcessor.FileImport.CSVProcessor
  alias Ports.AccountingIntegration

  @spec import_csv(String.t()) :: :ok
  def import_csv(file_path) do
    start_time = start_cut_timer_and_wait_to_avoid_imprecision_errors()

    with :ok <- upsert_and_validate_entries(file_path),
         :ok <- delete_all_older_entries_than(start_time) do
      Logger.info("CSV import completed successfully.")
      :ok
    else
      error ->
        Logger.error("CSV import from file path `#{file_path}` failed: `#{inspect(error)}`")
        :ok
    end
  end

  defp start_cut_timer_and_wait_to_avoid_imprecision_errors do
    start_time = NaiveDateTime.utc_now()
    :timer.sleep(1000)

    start_time
  end

  @spec upsert_and_validate_entries(String.t()) :: :ok | {:error, String.t()}
  defp upsert_and_validate_entries(file_path) do
    file_path
    |> build_vendor_data_from_csv()
    |> upsert_vendor_data()
    |> validate_vendor_data_upsert()
  end

  @spec build_vendor_data_from_csv(String.t()) :: list(VendorProcessor.VendorData.t())
  defp build_vendor_data_from_csv(file_path) do
    file_path
    |> File.stream!()
    |> CSVProcessor.process_csv_stream()
  end

  @spec upsert_vendor_data(list(VendorProcessor.VendorData.t())) :: list({:ok, any()} | {:error, any()})
  defp upsert_vendor_data(vendors_data) do
    Enum.map(vendors_data, fn vendor_data ->
      AccountingIntegration.resolve().upsert_vendor(vendor_data)
    end)
  end

  @spec validate_vendor_data_upsert(list({:ok, any()} | {:error, any()})) :: :ok | {:error, String.t()}
  defp validate_vendor_data_upsert(upsert_responses) do
    contains_error =
      Enum.any?(upsert_responses, fn upsert_response ->
        case upsert_response do
          {:ok, _} ->
            false

          {:error, _} ->
            Logger.error("Failed to upsert vendor data: #{inspect(upsert_responses)}")
            true
        end
      end)

    if contains_error, do: {:error, "Failed to upsert vendor data"}, else: :ok
  end

  @spec delete_all_older_entries_than(NaiveDateTime.t()) :: :ok
  defp delete_all_older_entries_than(time) do
    {:ok, all_vendors} = AccountingIntegration.resolve().list_all_vendors()

    Enum.each(all_vendors, fn vendor ->
      if NaiveDateTime.compare(vendor.updated_at, time) == :lt do
        Logger.info("Deleting vendor #{vendor.id} with updated_at #{vendor.updated_at} since it is older than #{time}")
        AccountingIntegration.resolve().delete_vendor(vendor.id)
      end
    end)

    :ok
  end
end
