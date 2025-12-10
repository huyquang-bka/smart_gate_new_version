package com.example.smart_gate_new_version

import android.content.Context
import com.scottyab.rootbeer.RootBeer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "root_check"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "isRooted") {
                result.success(checkIfRooted(applicationContext))
            } else {
                result.notImplemented()
            }
        }
    }

    private fun checkIfRooted(context: Context): Boolean {
        val rootBeer = RootBeer(context)
        return rootBeer.isRooted
    }
}
