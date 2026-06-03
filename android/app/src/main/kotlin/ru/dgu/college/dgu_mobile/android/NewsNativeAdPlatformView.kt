package ru.dgu.college.dgu_mobile.android

import android.content.Context
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import com.yandex.mobile.ads.common.AdRequest
import com.yandex.mobile.ads.common.AdRequestError
import com.yandex.mobile.ads.nativeads.MediaView
import com.yandex.mobile.ads.nativeads.NativeAd
import com.yandex.mobile.ads.nativeads.NativeAdException
import com.yandex.mobile.ads.nativeads.NativeAdLoadListener
import com.yandex.mobile.ads.nativeads.NativeAdLoader
import com.yandex.mobile.ads.nativeads.NativeAdView
import com.yandex.mobile.ads.nativeads.NativeAdViewBinder
import io.flutter.plugin.platform.PlatformView

class NewsNativeAdPlatformView(
    context: Context,
    private val adUnitId: String,
) : PlatformView {

    private val nativeAdView: NativeAdView =
        LayoutInflater.from(context).inflate(
            R.layout.layout_news_native_ad,
            null,
        ) as NativeAdView

    private val loader = NativeAdLoader(context)
    private var nativeAd: NativeAd? = null

    init {
        loader.loadAd(
            AdRequest.Builder(adUnitId).build(),
            object : NativeAdLoadListener {
                override fun onAdLoaded(ad: NativeAd) {
                    bindAd(ad)
                }

                override fun onAdFailedToLoad(error: AdRequestError) {
                    Log.w(
                        "YandexAds",
                        "News native load failed (unit=$adUnitId): " +
                            "code=${error.code}, ${error.description}",
                    )
                    nativeAdView.visibility = View.INVISIBLE
                }
            },
        )
    }

    private fun bindAd(ad: NativeAd) {
        nativeAd = ad

        val media = nativeAdView.findViewById<MediaView>(R.id.native_ad_media)
        val title = nativeAdView.findViewById<TextView>(R.id.native_ad_title)
        val body = nativeAdView.findViewById<TextView>(R.id.native_ad_body)
        val domain = nativeAdView.findViewById<TextView>(R.id.native_ad_domain)
        val sponsored = nativeAdView.findViewById<TextView>(R.id.native_ad_sponsored)
        val feedback = nativeAdView.findViewById<ImageView>(R.id.native_ad_feedback)

        val binder = NativeAdViewBinder.Builder(nativeAdView)
            .setMediaView(media)
            .setTitleView(title)
            .setBodyView(body)
            .setDomainView(domain)
            .setSponsoredView(sponsored)
            .setFeedbackView(feedback)
            .build()

        try {
            ad.bindNativeAd(binder)
            nativeAdView.visibility = View.VISIBLE
        } catch (_: NativeAdException) {
            nativeAdView.visibility = View.INVISIBLE
        }
    }

    override fun getView(): View = nativeAdView

    override fun dispose() {
        loader.cancelLoading()
        nativeAd = null
    }
}
