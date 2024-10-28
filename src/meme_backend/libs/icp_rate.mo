import Text "mo:base/Text";
// This is a generated Motoko binding.
// Please use `import service "ic:canister_id"` instead to call canisters on the IC if possible.

module {
  public type Asset = { class_ : AssetClass; symbol : Text };
  public type AssetClass = { #Cryptocurrency; #FiatCurrency };
  public type ExchangeRate = {
    metadata : ExchangeRateMetadata;
    rate : Nat64;
    timestamp : Nat64;
    quote_asset : Asset;
    base_asset : Asset;
  };
  public type ExchangeRateError = {
    #AnonymousPrincipalNotAllowed;
    #CryptoQuoteAssetNotFound;
    #FailedToAcceptCycles;
    #ForexBaseAssetNotFound;
    #CryptoBaseAssetNotFound;
    #StablecoinRateTooFewRates;
    #ForexAssetsNotFound;
    #InconsistentRatesReceived;
    #RateLimited;
    #StablecoinRateZeroRate;
    #Other : { code : Nat32; description : Text };
    #ForexInvalidTimestamp;
    #NotEnoughCycles;
    #ForexQuoteAssetNotFound;
    #StablecoinRateNotFound;
    #Pending;
  };

  public func getExchangeRateErrorText(error : ExchangeRateError) : Text {
    switch (error) {
      case (#AnonymousPrincipalNotAllowed) {
        return "AnonymousPrincipalNotAllowed";
      };
      case (#CryptoQuoteAssetNotFound) { return "CryptoQuoteAssetNotFound" };
      case (#FailedToAcceptCycles) { return "FailedToAcceptCycles" };
      case (#ForexBaseAssetNotFound) { return "ForexBaseAssetNotFound" };
      case (#CryptoBaseAssetNotFound) { return "CryptoBaseAssetNotFound" };
      case (#StablecoinRateTooFewRates) { return "StablecoinRateTooFewRates" };
      case (#ForexAssetsNotFound) { return "ForexAssetsNotFound" };
      case (#InconsistentRatesReceived) { return "InconsistentRatesReceived" };
      case (#RateLimited) { return "RateLimited" };
      case (#StablecoinRateZeroRate) { return "StablecoinRateZeroRate" };
      case (#ForexInvalidTimestamp) { return "ForexInvalidTimestamp" };

      case (#NotEnoughCycles) { return "NotEnoughCycles" };
      case (#ForexQuoteAssetNotFound) { return "ForexQuoteAssetNotFound" };
      case (#StablecoinRateNotFound) { return "StablecoinRateNotFound" };
      case (#Pending) { return "Pending" };
      case _ {
        return "Other";
      };
    };
  };

  public type ExchangeRateMetadata = {
    decimals : Nat32;
    forex_timestamp : ?Nat64;
    quote_asset_num_received_rates : Nat64;
    base_asset_num_received_rates : Nat64;
    base_asset_num_queried_sources : Nat64;
    standard_deviation : Nat64;
    quote_asset_num_queried_sources : Nat64;
  };
  public type GetExchangeRateRequest = {
    timestamp : ?Nat64;
    quote_asset : Asset;
    base_asset : Asset;
  };
  public type GetExchangeRateResult = {
    #Ok : ExchangeRate;
    #Err : ExchangeRateError;
  };
  public type Self = actor {
    get_exchange_rate : shared GetExchangeRateRequest -> async GetExchangeRateResult;
  };
};
