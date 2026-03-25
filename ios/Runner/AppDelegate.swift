import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "dgu_mobile/date_range",
        binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "pickDateRange" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard let args = call.arguments as? [String: Any],
              let startMs = args["startMillis"] as? NSNumber,
              let endMs = args["endMillis"] as? NSNumber,
              let firstMs = args["firstMillis"] as? NSNumber,
              let lastMs = args["lastMillis"] as? NSNumber else {
          result(FlutterError(code: "bad_args", message: nil, details: nil))
          return
        }

        let startDate = Date(timeIntervalSince1970: startMs.doubleValue / 1000.0)
        let endDate = Date(timeIntervalSince1970: endMs.doubleValue / 1000.0)
        let firstDate = Date(timeIntervalSince1970: firstMs.doubleValue / 1000.0)
        let lastDate = Date(timeIntervalSince1970: lastMs.doubleValue / 1000.0)

        DispatchQueue.main.async {
          guard let root = self?.window?.rootViewController else {
            result(FlutterError(code: "no_vc", message: nil, details: nil))
            return
          }
          DateRangePickerPresenter.present(
            from: root,
            start: startDate,
            end: endDate,
            minimum: firstDate,
            maximum: lastDate,
            onDone: { s, e in
              let sm = Int64(s.timeIntervalSince1970 * 1000.0)
              let em = Int64(e.timeIntervalSince1970 * 1000.0)
              result(["startMillis": sm, "endMillis": em])
            },
            onCancel: {
              result(nil)
            }
          )
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

private enum DateRangePickerPresenter {
  static func present(
    from root: UIViewController,
    start: Date,
    end: Date,
    minimum: Date,
    maximum: Date,
    onDone: @escaping (Date, Date) -> Void,
    onCancel: @escaping () -> Void
  ) {
    let vc = UIViewController()
    vc.view.backgroundColor = .systemBackground
    vc.modalPresentationStyle = .pageSheet

    let toolbar = UIToolbar()
    toolbar.translatesAutoresizingMaskIntoConstraints = false

    let cancel = UIBarButtonItem(title: "Отмена", style: .plain, target: nil, action: nil)
    let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
    let done = UIBarButtonItem(title: "Готово", style: .done, target: nil, action: nil)
    toolbar.items = [cancel, flex, done]

    let title = UILabel()
    title.text = "Период"
    title.font = .preferredFont(forTextStyle: .headline)
    title.textAlignment = .center
    title.translatesAutoresizingMaskIntoConstraints = false

    let lbl1 = UILabel()
    lbl1.text = "Начало"
    lbl1.font = .preferredFont(forTextStyle: .subheadline)
    lbl1.translatesAutoresizingMaskIntoConstraints = false

    let p1 = UIDatePicker()
    p1.datePickerMode = .date
    p1.preferredDatePickerStyle = .wheels
    p1.date = start
    p1.minimumDate = minimum
    p1.maximumDate = maximum
    p1.translatesAutoresizingMaskIntoConstraints = false

    let lbl2 = UILabel()
    lbl2.text = "Конец"
    lbl2.font = .preferredFont(forTextStyle: .subheadline)
    lbl2.translatesAutoresizingMaskIntoConstraints = false

    let p2 = UIDatePicker()
    p2.datePickerMode = .date
    p2.preferredDatePickerStyle = .wheels
    p2.date = end
    p2.minimumDate = minimum
    p2.maximumDate = maximum
    p2.translatesAutoresizingMaskIntoConstraints = false

    let stack = UIStackView(arrangedSubviews: [
      toolbar, title, lbl1, p1, lbl2, p2,
    ])
    stack.axis = .vertical
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false

    vc.view.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: vc.view.safeAreaLayoutGuide.topAnchor, constant: 8),
      stack.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(lessThanOrEqualTo: vc.view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
    ])

    let helper = DateRangePickerActions(
      vc: vc,
      startPicker: p1,
      endPicker: p2,
      onDone: onDone,
      onCancel: onCancel
    )
    cancel.target = helper
    cancel.action = #selector(DateRangePickerActions.cancelTapped)
    done.target = helper
    done.action = #selector(DateRangePickerActions.doneTapped)

    objc_setAssociatedObject(vc, &AssociatedKeys.helper, helper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    vc.presentationController?.delegate = helper

    root.present(vc, animated: true)
  }
}

private enum AssociatedKeys {
  static var helper: UInt8 = 0
}

private final class DateRangePickerActions: NSObject, UIAdaptivePresentationControllerDelegate {
  weak var vc: UIViewController?
  weak var startPicker: UIDatePicker?
  weak var endPicker: UIDatePicker?
  let onDone: (Date, Date) -> Void
  let onCancel: () -> Void

  private var finished = false

  init(
    vc: UIViewController,
    startPicker: UIDatePicker,
    endPicker: UIDatePicker,
    onDone: @escaping (Date, Date) -> Void,
    onCancel: @escaping () -> Void
  ) {
    self.vc = vc
    self.startPicker = startPicker
    self.endPicker = endPicker
    self.onDone = onDone
    self.onCancel = onCancel
  }

  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    finishCancelIfNeeded()
  }

  private func finishCancelIfNeeded() {
    guard !finished else { return }
    finished = true
    onCancel()
  }

  @objc func cancelTapped() {
    vc?.dismiss(animated: true)
  }

  @objc func doneTapped() {
    guard let s = startPicker?.date, let e = endPicker?.date else { return }
    let lo = min(s, e)
    let hi = max(s, e)
    guard !finished else { return }
    finished = true
    let sm = lo
    let em = hi
    onDone(sm, em)
    vc?.dismiss(animated: true)
  }
}
