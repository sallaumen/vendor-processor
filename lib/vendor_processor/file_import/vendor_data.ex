defmodule VendorProcessor.FileImport.VendorData do
  @moduledoc """
  Documentation for `VendorData`.
  This module defines the structure of the vendor data.
  It uses the `@enforce_keys` attribute to ensure that all required fields are present when creating a new struct.
  The `t` type is defined to represent the structure of the vendor data.
  """

  @enforce_keys [
    :id,
    :name,
    :email,
    :phone,
    :address,
    :city,
    :state,
    :zip
  ]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          email: String.t(),
          phone: String.t(),
          address: String.t(),
          city: String.t(),
          state: String.t(),
          zip: String.t()
        }
end
