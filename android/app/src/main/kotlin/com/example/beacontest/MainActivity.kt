package com.example.beacontest

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    private val LOG_TAG = "MainActivity"
    private val CHANNEL = "com.example.telematic/minewsdk"
    private lateinit var methodChannel: MethodChannel

    companion object {
        private const val REQUEST_BLUETOOTH_PERMISSION = 1
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            if (call.method == "startMinewSDK") {
                Log.i(LOG_TAG, "hello Kt")
                checkBluetoothPermissions()
            }
        }
    }

    private fun checkBluetoothPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) { // Android 12+
            if (checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                requestPermissions(arrayOf(Manifest.permission.BLUETOOTH_CONNECT), REQUEST_BLUETOOTH_PERMISSION)
            } else {
                startBluetoothScanningService()
            }
        } else {
            startBluetoothScanningService() // For lower versions, no need to check
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_BLUETOOTH_PERMISSION) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                startBluetoothScanningService()
            } else {
//                killApp()
            }
        }
    }

    fun killApp() {
//        finishAffinity() // Finish all activities
        System.exit(0) // Optionally, forcefully kill the app
    }

    private lateinit var bluetoothStateReceiver: BluetoothStateReceiver

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        registerBluetoothStateReceiver()
    }

    private fun registerBluetoothStateReceiver() {
        bluetoothStateReceiver = BluetoothStateReceiver()
        val filter = IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
        registerReceiver(bluetoothStateReceiver, filter)
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(bluetoothStateReceiver)
    }

    private fun startBluetoothScanningService() {
        val intent = Intent(this, BluetoothScanningService::class.java)
        intent.action = BluetoothScanningService.ACTION_RESTART_SCANNING
        Log.i(LOG_TAG, "start bluetooth scanning kt")
        startForegroundService(intent)
    }
}