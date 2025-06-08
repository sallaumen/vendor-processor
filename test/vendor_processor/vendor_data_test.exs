defmodule VendorProcessor.VendorDataTest do
  use ExUnit.Case, async: true
  alias VendorProcessor.VendorData

  @valid_vendor_attrs %{
    id: "vendor-123",
    country: "US",
    name: "Test Vendor",
    email: "test@example.com",
    phone: "123-456-7890",
    address: "123 Main St",
    city: "Test City",
    state: "Test State",
    zip: "12345",
    currency: "USD"
  }

  describe "struct/2" do
    test "when all required fields provided, should create struct successfully" do
      vendor_data = struct(VendorData, @valid_vendor_attrs)

      assert vendor_data.id == "vendor-123"
      assert vendor_data.country == "US"
      assert vendor_data.name == "Test Vendor"
      assert vendor_data.email == "test@example.com"
      assert vendor_data.phone == "123-456-7890"
      assert vendor_data.address == "123 Main St"
      assert vendor_data.city == "Test City"
      assert vendor_data.state == "Test State"
      assert vendor_data.zip == "12345"
      assert vendor_data.currency == "USD"
      assert vendor_data.updated_at == nil
    end

    test "when optional updated_at field provided, should create struct with timestamp" do
      timestamp = ~N[2025-01-01 10:00:00]
      vendor_data = struct(VendorData, Map.put(@valid_vendor_attrs, :updated_at, timestamp))

      assert vendor_data.updated_at == timestamp
    end
  end

  describe "struct!/2" do
    test "when required id field missing, should raise ArgumentError" do
      attrs = Map.delete(@valid_vendor_attrs, :id)

      assert_raise ArgumentError,
                   ~r/the following keys must also be given when building struct VendorProcessor.VendorData:/,
                   fn ->
                     struct!(VendorData, attrs)
                   end
    end

    test "when multiple required fields missing, should raise ArgumentError" do
      attrs = Map.take(@valid_vendor_attrs, [:id, :email])

      assert_raise ArgumentError,
                   ~r/the following keys must also be given when building struct VendorProcessor.VendorData:/,
                   fn ->
                     struct!(VendorData, attrs)
                   end
    end
  end
end
