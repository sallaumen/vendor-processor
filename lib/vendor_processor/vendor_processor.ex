defmodule VendorProcessor.VendorProcessor do
  @moduledoc """
  Main API module for vendor processing operations.
  """
  alias VendorProcessor.FileImport.CSVImporter

  @spec import_csv(String.t()) :: :ok
  defdelegate import_csv(file_path), to: CSVImporter
end
