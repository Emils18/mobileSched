import 'dart:js_interop';

@JS('awsHubSyncOneSignalTags')
external void _syncOneSignalTags(JSString tagsJson);

@JS('awsHubSetOneSignalPushEnabled')
external void _setOneSignalPushEnabled(JSBoolean enabled);

void syncOneSignalTags(String tagsJson) {
  try {
    _syncOneSignalTags(tagsJson.toJS);
  } catch (_) {
    // OneSignal is initialized asynchronously; the JS bridge queues work.
  }
}

void setOneSignalPushEnabled(bool enabled) {
  try {
    _setOneSignalPushEnabled(enabled.toJS);
  } catch (_) {
    // Keep web settings from affecting native platforms or crashing startup.
  }
}
