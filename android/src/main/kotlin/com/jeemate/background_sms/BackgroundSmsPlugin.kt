package com.jeemate.background_sms

import android.content.Context
import android.content.IntentFilter
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler


/** BackgroundSmsPlugin */
class BackgroundSmsPlugin: MethodCallHandler, FlutterPlugin {
  companion object {
    lateinit var channel : MethodChannel
    val tag = "BackgroundSmsPlugin"
    // channel
    private const val SMS_CHANNEL = "background_sms"

    // methods
    private const val METHOD_RECEIVER_START = "startReceiver"
    private const val METHOD_RECEIVER_STOP = "stopReceiver"
    const val METHOD_ON_MESSAGE = "onMessageReceiver"
  }

  private var applicationContext: Context? = null
  private val msgReceiver: SmsReceiver = SmsReceiver()

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, SMS_CHANNEL)
    channel.setMethodCallHandler(this)

    applicationContext = binding.applicationContext
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    applicationContext = null
    channel.setMethodCallHandler(null)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      METHOD_RECEIVER_START -> {
        startReceiver()
        result.success(null)
      }
      METHOD_RECEIVER_STOP -> {
        stopReceiver()
        result.success(null)
      }
      else -> result.notImplemented()
    }
  }

  private fun startReceiver() {
    val intent = IntentFilter("android.provider.Telephony.SMS_RECEIVED")
    applicationContext!!.registerReceiver(msgReceiver, intent)
    Log.v(tag, "SmsReceiver - start receiver: ")
  }

  private fun stopReceiver() {
    try {
      applicationContext!!.unregisterReceiver(msgReceiver)
      Log.v(tag, "SmsReceiver - stop receiver: ")
    } catch (e: Exception) {
      Log.e(tag, "SmsReceiver Exception: $e")
    }
  }
}