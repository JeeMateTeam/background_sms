package com.jeemate.background_sms

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.provider.Telephony.Sms.Intents.SMS_RECEIVED_ACTION
import android.telephony.SmsMessage
import android.util.Log

class SmsReceiver : BroadcastReceiver() {
    var applicationContext: Context? = null
    override fun onReceive(context: Context, intent: Intent) {
        applicationContext = context
        Log.v(BackgroundSmsPlugin.tag, "SmsReceiver:onReceive")
        if (SMS_RECEIVED_ACTION == "android.provider.Telephony.SMS_RECEIVED") {
            val smsMessages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            handleMessage(smsMessages)
        }
    }

    private fun handleMessage(smsList: Array<SmsMessage>) {
        val messagesGroupedByOriginatingAddress: MutableMap<String?, StringBuilder> = HashMap()
        for (sms in smsList) {
            val address = sms.originatingAddress
            val messageBody = sms.messageBody
            if (!messagesGroupedByOriginatingAddress.containsKey(address)) {
                messagesGroupedByOriginatingAddress[address] = StringBuilder()
            }
            messagesGroupedByOriginatingAddress[address]!!.append(messageBody)
        }
        for ((address, value) in messagesGroupedByOriginatingAddress) {
            val msg = value.toString()
            Log.v(BackgroundSmsPlugin.tag, "SmsReceiver:handleMessage:\naddress=$address\nmsg=$msg")
            // send data into dart
            passMessageData(address, msg)
        }
    }

    private fun passMessageData(address: String?, body: String?) {
        val message: MutableMap<String, String?> = HashMap()
        message["address"] = address
        message["body"] = body
        Log.v(BackgroundSmsPlugin.tag, "SmsReceiver:passMessageData to Flutter")
        BackgroundSmsPlugin.channel.invokeMethod(BackgroundSmsPlugin.METHOD_ON_MESSAGE, message)
    }
}