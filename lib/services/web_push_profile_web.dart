import 'dart:js_util' as js_util;

void syncOneSignalTags(Map<String, String> tags) {
  try {
    js_util.callMethod<void>(
      js_util.globalThis,
      'awsHubSyncOneSignalTags',
      [tags],
    );
  } catch (_) {
    // OneSignal is initialized asynchronously; the JS bridge queues work.
  }
}

void setOneSignalPushEnabled(bool enabled) {
  try {
    js_util.callMethod<void>(
      js_util.globalThis,
      'awsHubSetOneSignalPushEnabled',
      [enabled],
    );
  } catch (_) {
    // Keep web settings from affecting native platforms or crashing startup.
  }
}
