# vendor-processor

Url: https://api.no.stage.vic.ai/v0
Documentation: https://docs.vic.ai

```
mix deps.get
mix compile
mix run process.exs
```

## Requirements

* Using Elixir, we need to parse these CSVs and put the vendors into the
  Vic system.
* CSVs provided are the final state that the api should be in.
* Some high level unit tests will be necessary.
* Vendors not present in the CSV should be deleted.
* Vendors should have their data updated with what is in the CSV.
* Synchronize all of `vendors-01.csv` into vic-api.
* Simulate a change of vendors by synchronizing `vendors-02.csv`.
* If time permits, simulate the worst case scenario where all vendors have
  changed with `vendors-03.csv`.
