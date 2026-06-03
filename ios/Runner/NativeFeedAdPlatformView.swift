import Flutter
import UIKit
import YandexMobileAds

// MARK: - Layout (обязательные поля: media, title, body, sponsored, feedback)

private final class NativeFeedAdView: NativeAdView {
  private let media = MediaView()
  private let titleLbl = UILabel()
  private let bodyLbl = UILabel()
  private let domainLbl = UILabel()
  private let sponsoredLbl = UILabel()
  private let feedbackBtn = UIButton(type: .system)

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
    bindAssets()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func bindAssets() {
    mediaView = media
    titleLabel = titleLbl
    bodyLabel = bodyLbl
    domainLabel = domainLbl
    sponsoredLabel = sponsoredLbl
    feedbackButton = feedbackBtn
  }

  private func setupUI() {
    media.translatesAutoresizingMaskIntoConstraints = false
    titleLbl.translatesAutoresizingMaskIntoConstraints = false
    bodyLbl.translatesAutoresizingMaskIntoConstraints = false
    domainLbl.translatesAutoresizingMaskIntoConstraints = false
    sponsoredLbl.translatesAutoresizingMaskIntoConstraints = false
    feedbackBtn.translatesAutoresizingMaskIntoConstraints = false

    titleLbl.font = .boldSystemFont(ofSize: 16)
    titleLbl.textColor = .black
    titleLbl.numberOfLines = 2

    bodyLbl.font = .systemFont(ofSize: 13)
    bodyLbl.textColor = UIColor(red: 0.39, green: 0.45, blue: 0.55, alpha: 1)
    bodyLbl.numberOfLines = 3

    domainLbl.font = .systemFont(ofSize: 11)
    domainLbl.textColor = bodyLbl.textColor
    domainLbl.numberOfLines = 1

    sponsoredLbl.font = .systemFont(ofSize: 10, weight: .medium)
    sponsoredLbl.textColor = .gray

    addSubview(media)
    addSubview(titleLbl)
    addSubview(bodyLbl)
    addSubview(domainLbl)
    addSubview(sponsoredLbl)
    addSubview(feedbackBtn)

    let pad: CGFloat = 20
    NSLayoutConstraint.activate([
      media.topAnchor.constraint(equalTo: topAnchor),
      media.leadingAnchor.constraint(equalTo: leadingAnchor),
      media.trailingAnchor.constraint(equalTo: trailingAnchor),
      media.heightAnchor.constraint(equalToConstant: 160),

      titleLbl.topAnchor.constraint(equalTo: media.bottomAnchor, constant: 8),
      titleLbl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: pad),
      titleLbl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -pad),

      bodyLbl.topAnchor.constraint(equalTo: titleLbl.bottomAnchor, constant: 4),
      bodyLbl.leadingAnchor.constraint(equalTo: titleLbl.leadingAnchor),
      bodyLbl.trailingAnchor.constraint(equalTo: titleLbl.trailingAnchor),

      domainLbl.topAnchor.constraint(equalTo: bodyLbl.bottomAnchor, constant: 4),
      domainLbl.leadingAnchor.constraint(equalTo: titleLbl.leadingAnchor),
      domainLbl.trailingAnchor.constraint(equalTo: titleLbl.trailingAnchor),

      sponsoredLbl.topAnchor.constraint(equalTo: domainLbl.bottomAnchor, constant: 6),
      sponsoredLbl.leadingAnchor.constraint(equalTo: titleLbl.leadingAnchor),
      sponsoredLbl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),

      feedbackBtn.centerYAnchor.constraint(equalTo: sponsoredLbl.centerYAnchor),
      feedbackBtn.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
    ])
  }
}

// MARK: - Platform view

final class NativeFeedAdPlatformView: NSObject, FlutterPlatformView {
  private let container = UIView()
  private let adView = NativeFeedAdView()
  private var loader: NativeAdLoader?
  private var nativeAd: NativeAd?
  private let adUnitId: String

  init(frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) {
    let map = args as? [String: Any]
    adUnitId = (map?["adUnitId"] as? String) ?? "demo-native-content-yandex"
    super.init()
    container.backgroundColor = .white
    adView.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(adView)
    NSLayoutConstraint.activate([
      adView.topAnchor.constraint(equalTo: container.topAnchor),
      adView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      adView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      adView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])
    loadAd()
  }

  func view() -> UIView {
    container
  }

  private func loadAd() {
    let loader = NativeAdLoader()
    self.loader = loader
    let request = AdRequest(adUnitID: adUnitId)
    let options = NativeAdOptions()
    loader.loadAd(with: request, options: options) { [weak self] result in
      DispatchQueue.main.async {
        guard let self else { return }
        switch result {
        case .success(let ad):
          self.bind(ad)
        case .failure(let error):
          NSLog("YandexAds: News native load failed (unit=\(self.adUnitId)): \(error)")
          self.adView.isHidden = true
        }
      }
    }
  }

  private func bind(_ ad: NativeAd) {
    nativeAd = ad
    do {
      try ad.bind(with: adView)
      adView.isHidden = false
    } catch {
      NSLog("YandexAds: bind failed: \(error)")
      adView.isHidden = true
    }
  }
}

final class NativeFeedAdPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    NativeFeedAdPlatformView(frame: frame, viewIdentifier: viewId, arguments: args)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}
