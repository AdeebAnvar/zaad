import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/settings_repository.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/domain/models/settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final AppDatabase db;
  SettingsRepositoryImpl(this.db);
  @override
  void saveSettingsToLocal(SettingsModel settingsModel) async {
    await db.delete(db.settings).go();

    await db.settingsDao.saveSettings(settingsModel);
    await RuntimeAppSettings.refreshFromLocalSettings();
  }

  @override
  Future<SettingsModel?> getSettingsFromLocal() => db.settingsDao.getSettings();
}
