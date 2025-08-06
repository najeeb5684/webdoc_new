


import AVFoundation // Import the AVFoundation framework
import UIKit
import Flutter
import Photos // Import the Photos framework
import flutter_local_notifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private var initialNotificationPayload: [AnyHashable: Any]? = nil  // Store notification payload

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
            GeneratedPluginRegistrant.register(with: registry)
        }

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
        }
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let pushChannel = FlutterMethodChannel(name: "com.webdoc.health/push_events",
                                               binaryMessenger: controller.binaryMessenger)
        pushChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard call.method == "getInitialPushPayload" else {
                result(FlutterMethodNotImplemented)
                return
            }
            result(self.initialNotificationPayload)
            self.initialNotificationPayload = nil // Clear payload after sending
        })

        // Store initial notification if app was launched by tapping a notification
        if let notification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            initialNotificationPayload = notification
        }

        let audioChannel = FlutterMethodChannel(name: "app.channel.audio",
                                                binaryMessenger: controller.binaryMessenger)
        audioChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "configureAudioSession":
                self.configureAudioSession(result: result)
            case "setSpeakerphoneOn":
                self.setSpeakerphoneOn(call: call, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        })

        // Register method channel for saving image
        let imageChannel = FlutterMethodChannel(name: "app.channel.image", binaryMessenger: controller.binaryMessenger)
        imageChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "saveImageToPhotos" {
                guard let arguments = call.arguments as? [String: Any],
                      let imageData = arguments["imageData"] as? FlutterStandardTypedData else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for saveImageToPhotos", details: nil))
                    return
                }

                guard let image = UIImage(data: imageData.data) else {
                    result(FlutterError(code: "IMAGE_DECODING_FAILED", message: "Failed to decode image data", details: nil))
                    return
                }

                self?.saveImageToPhotos(image: image) { success, error in
                    if success {
                        result(nil) // Success
                    } else {
                        result(FlutterError(code: "IMAGE_SAVE_FAILED", message: "Failed to save image to photos: \(error?.localizedDescription ?? "Unknown error")", details: nil))
                    }
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        })

        GeneratedPluginRegistrant.register(with: self)
        // The lines referencing ApplicationDelegate, were part of Facebook SDK so delete these

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        initialNotificationPayload = userInfo
        completionHandler(UIBackgroundFetchResult.newData)

    }

    override func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

        return true
    }

    // MARK: - Saving Image to Photos

    private func saveImageToPhotos(image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
                                                   PHAssetChangeRequest.creationRequestForAsset(from: image)
                                               }, completionHandler: { success, error in
            completion(success, error)
        })
    }

    // MARK: - Audio Session Configuration
    func configureAudioSession(result: @escaping FlutterResult) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .voiceChat)
            try session.setActive(true)
            result(nil)
        } catch {
            print("Error configuring audio session: \(error)")
            result(FlutterError(code: "AUDIO_SESSION_ERROR", message: "Failed to configure audio session: \(error)", details: nil))
        }
    }

    // MARK: - Set Speakerphone On
    func setSpeakerphoneOn(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let enable = args["enable"] as? Bool else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for setSpeakerphoneOn", details: nil))
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.overrideOutputAudioPort(enable ? .speaker : .none)
            result(nil)
        } catch {
            print("Error setting speakerphone: \(error)")
            result(FlutterError(code: "SPEAKERPHONE_ERROR", message: "Failed to set speakerphone: \(error)", details: nil))
        }
    }
}


/*

import AVFoundation // Import the AVFoundation framework
import UIKit
import Flutter
import Photos // Import the Photos framework
import flutter_local_notifications
@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

      FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
          GeneratedPluginRegistrant.register(with: registry)
      }

      if #available(iOS 10.0, *) {
          UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
      }
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let audioChannel = FlutterMethodChannel(name: "app.channel.audio",
                                          binaryMessenger: controller.binaryMessenger)
    audioChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "configureAudioSession":
        self.configureAudioSession(result: result)
      case "setSpeakerphoneOn":
        self.setSpeakerphoneOn(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    })

    // Register method channel for saving image
    let imageChannel = FlutterMethodChannel(name: "app.channel.image", binaryMessenger: controller.binaryMessenger)
        imageChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if call.method == "saveImageToPhotos" {
                guard let arguments = call.arguments as? [String: Any],
                      let imageData = arguments["imageData"] as? FlutterStandardTypedData else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for saveImageToPhotos", details: nil))
                    return
                }

                guard let image = UIImage(data: imageData.data) else {
                    result(FlutterError(code: "IMAGE_DECODING_FAILED", message: "Failed to decode image data", details: nil))
                    return
                }

                self?.saveImageToPhotos(image: image) { success, error in
                    if success {
                        result(nil) // Success
                    } else {
                        result(FlutterError(code: "IMAGE_SAVE_FAILED", message: "Failed to save image to photos: \(error?.localizedDescription ?? "Unknown error")", details: nil))
                    }
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Saving Image to Photos

    private func saveImageToPhotos(image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }, completionHandler: { success, error in
            completion(success, error)
        })
    }

  // MARK: - Audio Session Configuration
    func configureAudioSession(result: @escaping FlutterResult) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .voiceChat)
            try session.setActive(true)
            result(nil)
        } catch {
            print("Error configuring audio session: \(error)")
            result(FlutterError(code: "AUDIO_SESSION_ERROR", message: "Failed to configure audio session: \(error)", details: nil))
        }
    }

  // MARK: - Set Speakerphone On
    func setSpeakerphoneOn(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let enable = args["enable"] as? Bool else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for setSpeakerphoneOn", details: nil))
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.overrideOutputAudioPort(enable ? .speaker : .none)
            result(nil)
        } catch {
            print("Error setting speakerphone: \(error)")
            result(FlutterError(code: "SPEAKERPHONE_ERROR", message: "Failed to set speakerphone: \(error)", details: nil))
        }
    }
}
*/
