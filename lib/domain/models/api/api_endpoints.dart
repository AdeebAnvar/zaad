class ApiEndpoints {
  static const String commonBaseUrl = "https://dine-test.zaad2.com";

  static const String getBaseUrl = "/get-url";

  static const String getCompanyData = "/api/v1/sync/bootstrap";

  /// Paged per-resource fetches: client sends `page` and `module` (resource key) query params.
  /// See [SyncApi.pullData] and [PullDataRepositoryImpl.pullAndPersist].
  static const String pullData = "/api/v1/pull_records";
  static const String pushData = "/push";
}
