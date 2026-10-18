package com.example.iredroid

import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.hardware.ConsumerIrManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    companion object {
        private const val CHANNEL = "org.nslabs/irtransmitter"
        private const val UPDATE_CHANNEL = "org.nslabs/updater"
        private const val DEFAULT_HEX_FREQUENCY = 38028
    }

    private var irManager: ConsumerIrManager? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        irManager = getSystemService(Context.CONSUMER_IR_SERVICE) as? ConsumerIrManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "transmit" -> handleTransmit(call, result)
                    "transmitRaw" -> handleTransmitRaw(call, result)
                    "hasIrEmitter" -> result.success(irManager?.hasIrEmitter() ?: false)
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getVersion" -> result.success(versionInfo())
                    "canInstallPackages" -> result.success(canInstallPackages())
                    "openInstallSettings" -> {
                        openInstallSettings()
                        result.success(null)
                    }
                    "installApk" -> installApk(call, result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun handleTransmit(call: MethodCall, result: MethodChannel.Result) {
        val pattern = call.argument<List<Int>>("list")
        if (irManager == null) {
            result.error("NO_IR", "IR emitter not available", null)
            return
        }
        if (pattern == null) {
            result.error("NO_PATTERN", "No pattern provided", null)
            return
        }
        try {
            irManager?.transmit(DEFAULT_HEX_FREQUENCY, pattern.toIntArray())
            result.success("IR signal transmitted successfully")
        } catch (e: Exception) {
            result.error("TRANSMISSION_FAILED", "Failed to transmit: ${e.message}", null)
        }
    }

    private fun handleTransmitRaw(call: MethodCall, result: MethodChannel.Result) {
        val pattern = call.argument<List<Int>>("list")
        val frequency = call.argument<Int>("frequency")
        if (irManager == null) {
            result.error("NO_IR", "IR emitter not available", null)
            return
        }
        if (pattern == null || frequency == null) {
            result.error("NO_PATTERN_OR_FREQUENCY", "No pattern or frequency provided", null)
            return
        }
        try {
            irManager?.transmit(frequency, pattern.toIntArray())
            result.success("Raw IR signal transmitted successfully")
        } catch (e: Exception) {
            result.error("TRANSMISSION_FAILED", "Failed to transmit: ${e.message}", null)
        }
    }

    @Suppress("DEPRECATION")
    private fun versionInfo(): Map<String, Any> {
        val info = packageManager.getPackageInfo(packageName, 0)
        val code = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.longVersionCode.toInt()
        } else {
            info.versionCode
        }
        return mapOf(
            "versionCode" to code,
            "versionName" to (info.versionName ?: "")
        )
    }

    private fun canInstallPackages(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            packageManager.canRequestPackageInstalls()
        } else {
            true
        }
    }

    private fun openInstallSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            runCatching {
                startActivity(
                    Intent(
                        Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                        Uri.parse("package:$packageName")
                    ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                )
            }
        }
    }

    private fun installApk(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path")
        if (path.isNullOrBlank()) {
            result.error("NO_PATH", "APK path is missing", null)
            return
        }

        try {
            val file = File(path)
            if (!file.exists()) {
                result.error("NO_FILE", "APK file not found", null)
                return
            }

            val uri = FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                file
            )
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                clipData = ClipData.newRawUri("", uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("INSTALL_FAILED", e.message, null)
        }
    }
}
