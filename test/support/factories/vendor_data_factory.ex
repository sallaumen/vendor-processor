defmodule Support.Factories.VendorDataFactory do
  @moduledoc """
  Factory for creating VendorData test fixtures.
  """
  use ExMachina
  alias VendorProcessor.VendorData

  def generic_factory() do
    %VendorData{
      id: Enum.random(1..1_000_000),
      country: Enum.random(["US", "CA", "MX"]),
      name: "Test Vendor",
      email: Faker.Internet.email(),
      phone: Faker.Phone.EnUs.phone(),
      address: Faker.Address.street_address(),
      city: Faker.Address.city(),
      state: Faker.Address.state(),
      zip: 10_000..99_999 |> Enum.random() |> Integer.to_string(),
      currency: Enum.random(["USD", "CAD", "MXN"])
    }
  end
end
