defmodule VendorProcessor.VendorProcessor do
  alias VendorProcessor.FileImport.CSVImporter

  defdelegate import_csv(file_path), to: CSVImporter
end
