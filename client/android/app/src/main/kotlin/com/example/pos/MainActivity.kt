package com.example.pos_app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.example.pos_app/storage"
        private const val LEGACY_STORAGE_REQUEST = 51001
        /** Android 11 (API 30)+ — "All files access" instead of a runtime popup. */
        private const val ALL_FILES_ACCESS_MIN_SDK = Build.VERSION_CODES.R
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "androidSdkInt" -> result.success(Build.VERSION.SDK_INT)
                "needsAllFilesAccessGate" -> result.success(Build.VERSION.SDK_INT >= ALL_FILES_ACCESS_MIN_SDK)
                "publicDocumentsPath" -> {
                    result.success(
                        Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS).absolutePath,
                    )
                }
                "hasAllFilesAccess" -> result.success(hasAllFilesAccess())
                "requestLegacyStoragePermission" -> {
                    requestLegacyStoragePermission()
                    result.success(hasAllFilesAccess())
                }
                "openAllFilesAccessSettings", "openStorageSettings" -> {
                    openStorageSettings()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == LEGACY_STORAGE_REQUEST) {
            // Flutter will re-check via hasAllFilesAccess on resume.
        }
    }

    /** API 23–29: READ+WRITE. API 30+ (incl. Android 16): isExternalStorageManager(). */
    private fun hasAllFilesAccess(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true
        }
        if (Build.VERSION.SDK_INT >= ALL_FILES_ACCESS_MIN_SDK) {
            return Environment.isExternalStorageManager()
        }
        val read = ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE)
        val write = ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE)
        return read == PackageManager.PERMISSION_GRANTED &&
            write == PackageManager.PERMISSION_GRANTED
    }

    private fun requestLegacyStoragePermission() {
        if (Build.VERSION.SDK_INT >= ALL_FILES_ACCESS_MIN_SDK) return
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        val needed = mutableListOf<String>()
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_EXTERNAL_STORAGE)
            != PackageManager.PERMISSION_GRANTED
        ) {
            needed.add(Manifest.permission.READ_EXTERNAL_STORAGE)
        }
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.WRITE_EXTERNAL_STORAGE)
            != PackageManager.PERMISSION_GRANTED
        ) {
            needed.add(Manifest.permission.WRITE_EXTERNAL_STORAGE)
        }
        if (needed.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, needed.toTypedArray(), LEGACY_STORAGE_REQUEST)
        }
    }

    private fun openStorageSettings() {
        if (Build.VERSION.SDK_INT >= ALL_FILES_ACCESS_MIN_SDK) {
            openAllFilesAccessSettings()
            return
        }
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            intent.data = Uri.parse("package:$packageName")
            startActivity(intent)
        } catch (_: Exception) {
            startActivity(Intent(Settings.ACTION_SETTINGS))
        }
    }

    private fun openAllFilesAccessSettings() {
        if (Build.VERSION.SDK_INT < ALL_FILES_ACCESS_MIN_SDK) return
        try {
            val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
            intent.data = Uri.parse("package:$packageName")
            startActivity(intent)
        } catch (_: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION))
            } catch (_: Exception) {
                openStorageSettings()
            }
        }
    }
}
