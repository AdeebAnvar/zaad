class ApiEndpoints {
  static const String commonBaseUrl = "https://suite.zaadplatforms.com/api/getlink";

  static const String getCompanyData = "/api/v1/sync/bootstrap";

  static const String pullData = "/api/v1/pull_records";

  /// Local → server sync (sales, credit_sales, customers, …).
  static const String pushRecords = "/api/v1/push_records";
}
