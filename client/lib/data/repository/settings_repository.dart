import 'package:pos/domain/models/settings_model.dart';

abstract class SettingsRepository {
  Future<void> saveSettingsToLocal(SettingsModel settingsModel);
  Future<SettingsModel?> getSettingsFromLocal();
}
