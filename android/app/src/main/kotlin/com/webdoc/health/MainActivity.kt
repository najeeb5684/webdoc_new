package com.webdoc.health

import android.media.AudioManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "app.channel.audio"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "setSpeakerphoneOn") {
                val enable = call.argument<Boolean>("enable") ?: false
                val audioManager = getSystemService(AUDIO_SERVICE) as AudioManager

                // IMPORTANT: Set audio mode BEFORE setting speakerphone
                audioManager.mode = AudioManager.MODE_IN_COMMUNICATION // Use MODE_IN_COMMUNICATION for VoIP

                audioManager.isSpeakerphoneOn = enable
                result.success(null) // Indicate success
            } else {
                result.notImplemented()
            }
        }
    }
}