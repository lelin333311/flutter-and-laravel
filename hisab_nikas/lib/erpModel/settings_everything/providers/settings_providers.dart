import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/whatsapp_settings_model.dart';
import '../services/whatsapp_notification_service.dart';

final whatsappNotificationServiceProvider = Provider<WhatsAppNotificationService>((ref) {
  return WhatsAppNotificationService.instance;
});

class WhatsAppSettingsNotifier extends Notifier<WhatsAppSettings> {
  @override
  WhatsAppSettings build() {
    final service = ref.watch(whatsappNotificationServiceProvider);
    return service.settings;
  }

  void updateSettings(WhatsAppSettings newSettings) {
    state = newSettings;
  }
}

final whatsappSettingsNotifierProvider = NotifierProvider<WhatsAppSettingsNotifier, WhatsAppSettings>(
  WhatsAppSettingsNotifier.new,
);
