defmodule Support.Factories.Adapters.VicAiFactory do
  use ExMachina

  def vendor_response_factory() do
    %{
      "addressCity" => "Delphine",
      "addressPostalCode" => nil,
      "addressState" => "MA",
      "addressStreet" => "53735 DuBuque Loaf",
      "confirmedAt" => "2025-05-22T13:59:08Z",
      "countryCode" => "US",
      "currency" => "USD",
      "description" => nil,
      "email" => "virginie1945@kilback.info",
      "errors" => [],
      "externalData" => nil,
      "externalId" => "4398724109",
      "externalUpdatedAt" => "2025-01-01T00:00:00",
      "internalId" => "143601921",
      "internalUpdatedAt" => "2025-05-22T13:59:08Z",
      "name" => "Leuschke Sanford and Weber",
      "paymentTermId" => nil,
      "phone" => "(558) 802-0887",
      "poMatchingDocumentLevel" => false,
      "state" => "CONFIRMED",
      "tags" => [],
      "vendorGroupId" => nil
    }
  end
end
