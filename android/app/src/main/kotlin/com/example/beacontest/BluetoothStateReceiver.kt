package com.example.beacontest

import android.bluetooth.BluetoothAdapter
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.os.Handler
import android.os.Looper

class BluetoothStateReceiver : BroadcastReceiver() {
    private val LOG_TAG = "BluetoothStateReceiver"

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action

        if (action == BluetoothAdapter.ACTION_STATE_CHANGED) {
            val state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)
            when (state) {
                BluetoothAdapter.STATE_ON -> {
                    Log.i(LOG_TAG, "Bluetooth is ON")
                    val serviceIntent = Intent(context, BluetoothScanningService::class.java)
                    serviceIntent.action = BluetoothScanningService.ACTION_RESTART_SCANNING
                    context.startForegroundService(serviceIntent)
                }
                BluetoothAdapter.STATE_OFF -> {
                    Log.i(LOG_TAG, "Bluetooth is OFF")
                    stopBluetoothScanningService(context)
                    Handler(Looper.getMainLooper()).postDelayed({
                        killApp(context) // Call your function after 5 seconds
                    }, 5000)
                }
            }
        }
    }

    private fun stopBluetoothScanningService(context: Context) {
        val serviceIntent = Intent(context, BluetoothScanningService::class.java)
        context.stopService(serviceIntent)
    }

    private fun killApp(context: Context) {
        if (context is MainActivity) {
            context.killApp() // Call the method to kill the app from MainActivity
        }
    }
}