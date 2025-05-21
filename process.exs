# No vendors exist in the api
{:ok, vendors} = VendorProcessor.process("./vendors-01.csv")
:ok = VendorProcessor.update_api(vendors)

# Some vendors updated
# {:ok, vendors} = VendorProcessor.process("./vendors-02.csv")
# :ok = VendorProcessor.update_api(vendors)

# Worst case scenario
# {:ok, vendors} = VendorProcessor.process("./vendors-03.csv")
# :ok = VendorProcessor.update_api(vendors)
