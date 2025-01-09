package com.example.beacontest

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.minew.beaconplus.sdk.MTCentralManager
import com.minew.beaconplus.sdk.MTPeripheral
import com.minew.beaconplus.sdk.enums.FrameType
import com.minew.beaconplus.sdk.frames.*
import com.minew.beaconplus.sdk.interfaces.MTCentralManagerListener
import com.google.gson.Gson
import java.io.File
import java.io.IOException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.delay

import com.example.beacontest.R

class BluetoothScanningService : Service(), MTCentralManagerListener {

    private val LOG_TAG = "BluetoothScanningService"
    private var mtCentralManager: MTCentralManager? = null
    private val CHANNEL = "com.example.telematic/minewsdk"
//    private var counter = 0

    companion object {
        const val ACTION_RESTART_SCANNING = "com.example.beacontest.ACTION_RESTART_SCANNING"
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_RESTART_SCANNING) {
            Log.i(LOG_TAG, "Restarting scanning")
            onCreate()
//            startForegroundService()
//            startScanning()
        }
        return START_STICKY
    }

    override fun onCreate() {
        super.onCreate()
        startForegroundService()
        startScanning()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun startForegroundService() {
        Log.i(LOG_TAG, "start foreground kt")

        val channelId = "bluetooth_scanning_channel"
        val channelName = "Bluetooth Scanning Service"
        val notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_MIN)
        notificationManager.createNotificationChannel(channel)

        val notification: Notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Bluetooth Scanning Started")
            .setContentText("Scanning for Beacons...")
            .setSmallIcon(R.mipmap.ic_launcher)
            .build()

        startForeground(1, notification)
    }

    private fun startScanning() {
        Log.i(LOG_TAG, "in start")
        mtCentralManager = MTCentralManager.getInstance(applicationContext)
        try {
//            mtCentralManager?.let {
//                it.stopScan()
//                it.clear()
//                it.setMTCentralManagerListener(this)
//                it.startService()
//                it.startScan()
//            }
            mtCentralManager?.let { manager: MTCentralManager ->
//                manager.startScan()

                // Add a delay before stopping the scan using coroutines
                CoroutineScope(Dispatchers.Main).launch {
                    delay(3000) // Delay in milliseconds (e.g., 5000ms = 5 seconds)
                    manager.stopScan()
                    manager.clear()
                    manager.setMTCentralManagerListener(this@BluetoothScanningService)
                    manager.startService()
                    manager.startScan()
                }
            }
        } catch (e: Exception) {
            Log.i(LOG_TAG, "..... an error occurred $e .....")
        }
        Log.i(LOG_TAG, ".....11111111")
    }

    override fun onScanedPeripheral(peripherals: List<MTPeripheral>) {
        Log.i(LOG_TAG, "Scanned peripherals: ${peripherals.size}")
        // Handle scanned peripherals and write to file as in your MainActivity
        val beacons = peripherals.map { mtPeripheral ->
            val mtFrameHandler = mtPeripheral.mMTFrameHandler
//            Log.i(LOG_TAG, "WAWAWAWAWWAWAWAWAWAWAWWWWAWAAWAWAWAWA ${mtFrameHandler.mac}")
            mapOf(
                "mac" to mtFrameHandler.mac,
                "name" to mtFrameHandler.name,
                "battery" to mtFrameHandler.battery,
                "rssi" to mtFrameHandler.rssi,
                "lastUpdate" to mtFrameHandler.lastUpdate.toDouble(),
                "frames" to mtFrameHandler.advFrames.map { frame ->
                    when (frame.frameType) {
                        FrameType.FrameiBeacon -> {
                            frame as IBeaconFrame
                            mapOf(
                                "type" to "ibeacon",
                                "uuid" to frame.uuid,
                                "major" to frame.major,
                                "minor" to frame.minor,
                                "tx" to frame.txPower
                            )
                        }
                        FrameType.FrameUID -> {
                            frame as UidFrame
                            mapOf(
                                "type" to "uid",
                                "instance" to frame.instanceId,
                                "namespace" to frame.namespaceId
                            )
                        }
                        FrameType.FrameAccSensor -> {
                            frame as AccFrame
                            mapOf(
                                "type" to "accelerometer",
                                "x" to frame.xAxis,
                                "y" to frame.yAxis,
                                "z" to frame.zAxis
                            )
                        }
                        FrameType.FrameHTSensor -> {
                            frame as HTFrame
                            mapOf(
                                "type" to "ht",
                                "temperature" to frame.temperature,
                                "humidity" to frame.humidity
                            )
                        }
                        FrameType.FrameTLM -> {
                            frame as TlmFrame
                            mapOf(
                                "type" to "tlm",
                                "temperature" to frame.temperature,
                                "batteryVol" to frame.batteryVol,
                                "secCount" to frame.secCount,
                                "advCount" to frame.advCount
                            )
                        }
                        FrameType.FrameURL -> {
                            frame as UrlFrame
                            mapOf(
                                "type" to "url",
                                "tx" to frame.txPower,
                                "url" to frame.urlString
                            )
                        }
                        FrameType.FrameLightSensor -> {
                            frame as LightFrame
                            mapOf(
                                "type" to "light",
                                "battery" to frame.battery,
                                "lux" to frame.luxValue
                            )
                        }
                        FrameType.FrameForceSensor -> {
                            frame as ForceFrame
                            mapOf(
                                "type" to "force",
                                "battery" to frame.battery,
                                "force" to frame.force
                            )
                        }
                        FrameType.FramePIRSensor -> {
                            frame as PIRFrame
                            mapOf(
                                "type" to "pir",
                                "battery" to frame.battery
                            )
                        }
                        FrameType.FrameTempSensor -> {
                            frame as TemperatureFrame
                            mapOf(
                                "type" to "temperature",
                                "battery" to frame.battery,
                                "temperature" to frame.value.toDouble()
                            )
                        }
                        FrameType.FrameTVOCSensor -> {
                            frame as TvocFrame
                            mapOf(
                                "type" to "tvoc",
                                "battery" to frame.battery,
                                "tvoc" to frame.value
                            )
                        }
                        FrameType.FrameLineBeacon -> {
                            frame as LineBeaconFrame
                            mapOf(
                                "type" to "line",
                                "hwid" to frame.hwid,
                                "tx" to frame.txPower,
                                "auth" to frame.authentication,
                                "timestamp" to frame.timesTamp
                            )
                        }
                        FrameType.FrameDeviceInfo -> {
                            frame as DeviceInfoFrame
                            mapOf(
                                "type" to "info",
                                "mac" to frame.mac,
                                "name" to frame.name,
                                "battery" to frame.battery
                            )
                        }
                        // Handle other frame types similarly...
                        else -> mapOf("type" to "unknown")
                    }
                }
            )
        }
        try {
            val gson = Gson()
            val jsonString = gson.toJson(beacons)
            writeFile(jsonString)
        } catch (e: Exception) {
            Log.e(LOG_TAG, "Error writing file: ${e.message}")
        }

//        if (counter == 10) {
//            counter = 0
//            clearFile()
//            restartScanning()
//        }
    }

    private fun writeFile(jsonString: String) {
        try {
            Log.i(LOG_TAG, "writin file")
            val file = File("/data/user/0/com.example.beacontest/app_flutter", "beacons.json")
            file.writeText(jsonString)
        } catch (e: IOException) {
            Log.e(LOG_TAG, "Error writing file: ${e.message}")
        }
    }

    fun clearFile() {
        try {
            val file = File("/data/user/0/com.example.telematic/app_flutter", "beacons.json")
            if (file.exists()) {
                file.writeText("")
                Log.d(LOG_TAG, "File cleared successfully.")
            } else {
                Log.d(LOG_TAG, "File does not exist.")
            }
        } catch (e: IOException) {
            Log.e(LOG_TAG, "Error clearing file: ${e.message}")
        }
    }

    private fun restartScanning() {
        Log.i(LOG_TAG, "in rsrt")
        mtCentralManager?.let {
            it.stopScan()
            it.clear()
            it.startScan()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        mtCentralManager?.let {
            it.stopScan()
            it.stopService()
        }
    }
}
