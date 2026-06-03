package ru.dgu.college.dgu_mobile.android

import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class NewsNativeAdPlatformViewFactory :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val map = args as? Map<*, *> ?: emptyMap<Any, Any>()
        val adUnitId = map["adUnitId"] as? String ?: "demo-native-content-yandex"
        return NewsNativeAdPlatformView(context, adUnitId)
    }
}
