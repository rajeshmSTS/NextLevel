//
//  CameraViewController.swift
//  NextLevel (http://nextlevel.engineering/)
//
//  Copyright (c) 2016-present patrick piemonte (http://patrickpiemonte.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit
import AVFoundation
import Photos
//import NextLevel

let CameraViewControllerAlbumTitle = "Next Level"

class CameraViewController: UIViewController {

    // MARK: - UIViewController

    override public var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - properties
    
    internal var previewView: UIView?
    internal var gestureView: UIView?
    internal var controlDockView: UIView?

    internal var recordButton: UIImageView?
    internal var flipButton: UIButton?
    internal var flashButton: UIButton?
    internal var saveButton: UIButton?

    internal var longPressGestureRecognizer: UILongPressGestureRecognizer?
    internal var photoTapGestureRecognizer: UITapGestureRecognizer?
    internal var focusTapGestureRecognizer: UITapGestureRecognizer?
    internal var zoomPanGestureRecognizer: UIPanGestureRecognizer?
    internal var flipDoubleTapGestureRecognizer: UITapGestureRecognizer?
    
    // MARK: - object lifecycle
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)
    }
    
    deinit {
    }
    
    // MARK: - view lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.black
        self.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let screenBounds = UIScreen.main.bounds

        // preview
        self.previewView = UIView(frame: screenBounds)
        if let previewView = self.previewView {
            previewView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            previewView.backgroundColor = UIColor.black
            NextLevel.sharedInstance.previewLayer.frame = previewView.bounds
            previewView.layer.addSublayer(NextLevel.sharedInstance.previewLayer)
            self.view.addSubview(previewView)
        }
        
        // buttons
        self.recordButton = UIImageView(image: UIImage(named: "record_button"))
        self.longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGestureRecognizer(_:)))
        if let recordButton = self.recordButton,
            let longPressGestureRecognizer = self.longPressGestureRecognizer {
            recordButton.isUserInteractionEnabled = true
            recordButton.sizeToFit()
            
            longPressGestureRecognizer.delegate = self
            longPressGestureRecognizer.minimumPressDuration = 0.05
            longPressGestureRecognizer.allowableMovement = 10.0
            recordButton.addGestureRecognizer(longPressGestureRecognizer)
        }
        
        self.flipButton = UIButton(type: .custom)
        if let flipButton = self.flipButton {
            flipButton.setImage(UIImage(named: "flip_button"), for: .normal)
            flipButton.sizeToFit()
            flipButton.addTarget(self, action: #selector(handleFlipButton(_:)), for: .touchUpInside)
        }
        
        self.saveButton = UIButton(type: .custom)
        if let saveButton = self.saveButton {
            saveButton.setImage(UIImage(named: "save_button"), for: .normal)
            saveButton.sizeToFit()
            saveButton.addTarget(self, action: #selector(handleSaveButton(_:)), for: .touchUpInside)
        }
        
        // capture control "dock"
        let controlDockHeight = screenBounds.height * 0.2
        self.controlDockView = UIView(frame: CGRect(x: 0, y: screenBounds.height - controlDockHeight, width: screenBounds.width, height: controlDockHeight))
        if let controlDockView = self.controlDockView {
            controlDockView.backgroundColor = UIColor.clear
            controlDockView.autoresizingMask = [.flexibleTopMargin]
            self.view.addSubview(controlDockView)
            
            if let recordButton = self.recordButton {
                recordButton.center = CGPoint(x: controlDockView.bounds.midX, y: controlDockView.bounds.midY)
                controlDockView.addSubview(recordButton)
            }
            
            if let flipButton = self.flipButton, let recordButton = self.recordButton {
                flipButton.center = CGPoint(x: recordButton.center.x + controlDockView.bounds.width * 0.25 + flipButton.bounds.width * 0.5, y: recordButton.center.y)
                controlDockView.addSubview(flipButton)
            }
            
            if let saveButton = self.saveButton, let recordButton = self.recordButton {
                saveButton.center = CGPoint(x: controlDockView.bounds.width * 0.25 - saveButton.bounds.width * 0.5, y: recordButton.center.y)
                controlDockView.addSubview(saveButton)
            }
        }
        
        // gestures
        self.gestureView = UIView(frame: screenBounds)
        if let gestureView = self.gestureView, let controlDockView = self.controlDockView {
            gestureView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
            gestureView.frame.size.height -= controlDockView.frame.height
            gestureView.backgroundColor = .clear
            self.view.addSubview(gestureView)

            self.focusTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleFocusTapGestureRecognizer(_:)))
            if let focusTapGestureRecognizer = self.focusTapGestureRecognizer {
                focusTapGestureRecognizer.delegate = self
                focusTapGestureRecognizer.numberOfTapsRequired = 1
                gestureView.addGestureRecognizer(focusTapGestureRecognizer)
            }
        }
        
        // Configure NextLevel by modifying the configuration ivars
        let nextLevel = NextLevel.sharedInstance
        nextLevel.delegate = self
        nextLevel.flashDelegate = self
        nextLevel.videoDelegate = self
        nextLevel.photoDelegate = self
        
        // video configuration
        nextLevel.videoConfiguration.bitRate = 2000000
//        nextLevel.videoConfiguration.dimensions = CGSize(width: 1280, height: 720)
        nextLevel.videoConfiguration.scalingMode = AVVideoScalingModeResizeAspectFill
        
        // audio configuration
        nextLevel.audioConfiguration.bitRate = 128000
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let nextLevel = NextLevel.sharedInstance
        if nextLevel.authorizationStatus(forMediaType: AVMediaTypeVideo) == .authorized &&
            nextLevel.authorizationStatus(forMediaType: AVMediaTypeAudio) == .authorized {
            do {
                try nextLevel.start()
            } catch {
                print("NextLevel, failed to start camera session")
            }
        } else {
            nextLevel.requestAuthorization(forMediaType: AVMediaTypeVideo)
            nextLevel.requestAuthorization(forMediaType: AVMediaTypeAudio)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NextLevel.sharedInstance.stop()
    }
    
}

// MARK: - library

extension CameraViewController {
    
    internal func albumAssetCollection(withTitle title: String) -> PHAssetCollection? {
        let predicate = NSPredicate(format: "localizedTitle = %@", title)
        let options = PHFetchOptions()
        options.predicate = predicate
        let result = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: options)
        if result.count > 0 {
            return result.firstObject
        }
        return nil
    }
    
}

// MARK: - capture

extension CameraViewController {
    
    internal func startCapture() {
        self.photoTapGestureRecognizer?.isEnabled = false
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut, animations: {
            self.recordButton?.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        }) { (completed: Bool) in
        }
        NextLevel.sharedInstance.record()
    }
    
    internal func pauseCapture() {
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: {
            self.recordButton?.transform = .identity
        }) { (completed: Bool) in
        }
        NextLevel.sharedInstance.pause()
    }
    
    internal func endCapture() {
        self.photoTapGestureRecognizer?.isEnabled = true
        NextLevel.sharedInstance.session?.mergeClips(usingPreset: AVAssetExportPresetHighestQuality, completionHandler: { (url: URL?, error: Error?) in
            if let videoURL = url {
                
                PHPhotoLibrary.shared().performChanges({

                    let albumAssetCollection = self.albumAssetCollection(withTitle: CameraViewControllerAlbumTitle)
                    if albumAssetCollection == nil {
                        let changeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: CameraViewControllerAlbumTitle)
                        let _ = changeRequest.placeholderForCreatedAssetCollection
                    }
                        
                }, completionHandler: { (success1: Bool, error1: Error?) in
                    
                    if success1 == true {
                        if let albumAssetCollection = self.albumAssetCollection(withTitle: CameraViewControllerAlbumTitle) {
                            PHPhotoLibrary.shared().performChanges({
                                if let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL) {
                                    let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: albumAssetCollection)
                                    let enumeration: NSArray = [assetChangeRequest.placeholderForCreatedAsset!]
                                    assetCollectionChangeRequest?.addAssets(enumeration)
                                }
                            }, completionHandler: { (success2: Bool, error2: Error?) in
                                if success2 == true {
                                    // remove the session's clips, after saving (if desired)
                                    NextLevel.sharedInstance.session?.removeAllClips()
    
                                    // prompt that the video has been saved
                                    let alertController = UIAlertController(title: "Video Saved!", message: "Saved to the camera roll.", preferredStyle: .alert)
                                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                    alertController.addAction(okAction)
                                    self.present(alertController, animated: true, completion: nil)
                                }
                            })
                        }
                    } else if let _ = error1 {
                        print("failure saving video \(error1)")
                    }
                    
                })
                
            } else if let _ = error {
                print("failed to merge clips at the end of capture \(error)")
            }
        })
    }
    
}

// MARK: - UIButton

extension CameraViewController {

    internal func handleFlipButton(_ button: UIButton) {
        NextLevel.sharedInstance.flipCaptureDevicePosition()
    }
    
    internal func handleFlashModeButton(_ button: UIButton) {
    }
    
    internal func handleSaveButton(_ button: UIButton) {
        self.endCapture()
    }
    
}

// MARK: - UIGestureRecognizer

extension CameraViewController: UIGestureRecognizerDelegate {

    internal func handleLongPressGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            self.startCapture()
            break
        case .ended:
            fallthrough
        case .cancelled:
            fallthrough
        case .failed:
            self.pauseCapture()
            fallthrough
        default:
            break
        }
    }
    
    internal func handlePhotoTapGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        NextLevel.sharedInstance.capturePhotoFromVideo()
    }
    
    internal func handleFocusTapGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        let tapPoint = gestureRecognizer.location(in: self.previewView)

        // TODO: create focus view and animate
        
        let previewLayer = NextLevel.sharedInstance.previewLayer
        let adjustedPoint = previewLayer.captureDevicePointOfInterest(for: tapPoint)
        NextLevel.sharedInstance.focusExposeAndAdjustWhiteBalance(atAdjustedPoint: adjustedPoint)
    }
    
}

// MARK: - NextLevelDelegate

extension CameraViewController: NextLevelDelegate {

    // permission
    func nextLevel(_ nextLevel: NextLevel, didUpdateAuthorizationStatus status: NextLevelAuthorizationStatus, forMediaType mediaType: String) {
        print("NextLevel, authorization updated for media \(mediaType) status \(status)")
        if nextLevel.authorizationStatus(forMediaType: AVMediaTypeVideo) == .authorized &&
            nextLevel.authorizationStatus(forMediaType: AVMediaTypeAudio) == .authorized {
            do {
                try nextLevel.start()
            } catch {
                print("NextLevel, failed to start camera session")
            }
        } else if status == .notAuthorized {
            // gracefully handle when audio/video is not authorized
            print("NextLevel doesn't have authorization for audio or video")
        }
    }
    
    // configuration
    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoConfiguration videoConfiguration: NextLevelVideoConfiguration) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didUpdateAudioConfiguration audioConfiguration: NextLevelAudioConfiguration) {
    }
    
    // session
    func nextLevelSessionWillStart(_ nextLevel: NextLevel) {
        print("nextLevelSessionWillStart")
    }
    
    func nextLevelSessionDidStart(_ nextLevel: NextLevel) {
        print("nextLevelSessionDidStart")
    }
    
    func nextLevelSessionDidStop(_ nextLevel: NextLevel) {
        print("nextLevelSessionDidStop")
    }
    
    // preview
    func nextLevelWillStartPreview(_ nextLevel: NextLevel) {
    }
    
    func nextLevelDidStopPreview(_ nextLevel: NextLevel) {
    }
    
    // device position, mode, and orientation
    func nextLevelDevicePositionWillChange(_ nextLevel: NextLevel) {
    }
    
    func nextLevelDevicePositionDidChange(_ nextLevel: NextLevel) {
    }
    
    func nextLevelCaptureModeWillChange(_ nextLevel: NextLevel) {
    }
    
    func nextLevelCaptureModeDidChange(_ nextLevel: NextLevel) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didChangeDeviceOrientation deviceOrientation: NextLevelDeviceOrientation) {
    }
    
    // aperture
    func nextLevel(_ nextLevel: NextLevel, didChangeCleanAperture cleanAperture: CGRect) {
    }
    
    // focus, exposure, white balance
    func nextLevelWillStartFocus(_ nextLevel: NextLevel) {
    }
    
    func nextLevelDidStopFocus(_  nextLevel: NextLevel) {
    }
    
    func nextLevelWillChangeExposure(_ nextLevel: NextLevel) {
    }
    
    func nextLevelDidChangeExposure(_ nextLevel: NextLevel) {
    }
    
    func nextLevelWillChangeWhiteBalance(_ nextLevel: NextLevel) {
    }
    
    func nextLevelDidChangeWhiteBalance(_ nextLevel: NextLevel) {
    }
    
}

// MARK: - NextLevelFlashDelegate

extension CameraViewController: NextLevelFlashDelegate {
    
    func nextLevelDidChangeFlashMode(_ nextLevel: NextLevel) {
    }
    
    func nextLevelDidChangeTorchMode(_ nextLevel: NextLevel) {
    }
    
    func nextLevelFlashActiveChanged(_ nextLevel: NextLevel) {
    }
    
    func nextLevelTorchActiveChanged(_ nextLevel: NextLevel) {
    }
    
    func nextLevelFlashAndTorchAvailabilityChanged(_ nextLevel: NextLevel) {
    }

}

// MARK: - NextLevelVideoDelegate

extension CameraViewController: NextLevelVideoDelegate {

    // video zoom
    func nextLevel(_ nextLevel: NextLevel, didUpdateVideoZoomFactor videoZoomFactor: Float) {
    }

    // video frame processing
    func nextLevel(_ nextLevel: NextLevel, willProcessRawVideoSampleBuffer sampleBuffer: CMSampleBuffer) {
    }
    
    // enabled by isCustomContextVideoRenderingEnabled
    func nextLevel(_ nextLevel: NextLevel, renderToCustomContextWithImageBuffer imageBuffer: CVPixelBuffer, onQueue queue: DispatchQueue) {
    }
    
    // video recording session
    func nextLevel(_ nextLevel: NextLevel, didSetupVideoInSession session: NextLevelSession) {
//        print("setup video")
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSetupAudioInSession session: NextLevelSession) {
//        print("setup audio")
    }
    
    func nextLevel(_ nextLevel: NextLevel, didStartClipInSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didCompleteClip clip: NextLevelClip, inSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didAppendVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didAppendAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSkipVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didSkipAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didCompleteSession session: NextLevelSession) {
        // called when a configuration time limit is specified
        self.endCapture()
    }
    
    // video frame photo

    func nextLevel(_ nextLevel: NextLevel, didCompletePhotoCaptureFromVideoFrame photoDict: [String : Any]?) {
        
        if let dictionary = photoDict,
            let photoData = dictionary[NextLevelPhotoJPEGKey] {
            
            PHPhotoLibrary.shared().performChanges({
                
                let albumAssetCollection = self.albumAssetCollection(withTitle: CameraViewControllerAlbumTitle)
                if albumAssetCollection == nil {
                    let changeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: CameraViewControllerAlbumTitle)
                    let _ = changeRequest.placeholderForCreatedAssetCollection
                }
            
            }, completionHandler: { (success1: Bool, error1: Error?) in
                
                if success1 == true {
                    if let albumAssetCollection = self.albumAssetCollection(withTitle: CameraViewControllerAlbumTitle) {
                        PHPhotoLibrary.shared().performChanges({
                            if let photoImage = UIImage(data: photoData as! Data) {
                                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: photoImage)
                                let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: albumAssetCollection)
                                let enumeration: NSArray = [assetChangeRequest.placeholderForCreatedAsset!]
                                assetCollectionChangeRequest?.addAssets(enumeration)
                            }
                        }, completionHandler: { (success2: Bool, error2: Error?) in
                            if success2 == true {
                                let alertController = UIAlertController(title: "Photo Saved!", message: "Saved to the camera roll.", preferredStyle: .alert)
                                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                alertController.addAction(okAction)
                                self.present(alertController, animated: true, completion: nil)
                            }
                        })
                    }
                } else if let _ = error1 {
                    print("failure capturing photo from video frame \(error1)")
                }
                
            })
        
        }
        
    }
    
}

// MARK: - NextLevelPhotoDelegate

extension CameraViewController: NextLevelPhotoDelegate {
    
    // photo
    func nextLevel(_ nextLevel: NextLevel, willCapturePhotoWithConfiguration photoConfiguration: NextLevelPhotoConfiguration) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didCapturePhotoWithConfiguration photoConfiguration: NextLevelPhotoConfiguration) {
    }
    
    func nextLevel(_ nextLevel: NextLevel, didProcessPhotoCaptureWith photoDict: [String : Any]?, photoConfiguration: NextLevelPhotoConfiguration) {
        
        if let dictionary = photoDict,
            let photoData = dictionary[NextLevelPhotoJPEGKey] {

            PHPhotoLibrary.shared().performChanges({
                
                let albumAssetCollection = self.albumAssetCollection(withTitle: CameraViewControllerAlbumTitle)
                if albumAssetCollection == nil {
                    let changeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: CameraViewControllerAlbumTitle)
                    let _ = changeRequest.placeholderForCreatedAssetCollection
                }
                
            }, completionHandler: { (success1: Bool, error1: Error?) in
                    
                if success1 == true {
                    if let albumAssetCollection = self.albumAssetCollection(withTitle: CameraViewControllerAlbumTitle) {
                        PHPhotoLibrary.shared().performChanges({
                            if let photoImage = UIImage(data: photoData as! Data) {
                                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: photoImage)
                                let assetCollectionChangeRequest = PHAssetCollectionChangeRequest(for: albumAssetCollection)
                                let enumeration: NSArray = [assetChangeRequest.placeholderForCreatedAsset!]
                                assetCollectionChangeRequest?.addAssets(enumeration)
                            }
                        }, completionHandler: { (success2: Bool, error2: Error?) in
                            if success2 == true {
                                let alertController = UIAlertController(title: "Photo Saved!", message: "Saved to the camera roll.", preferredStyle: .alert)
                                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                                alertController.addAction(okAction)
                                self.present(alertController, animated: true, completion: nil)
                            }
                        })
                    }
                } else if let _ = error1 {
                    print("failure capturing photo from video frame \(error1)")
                }
                    
            })
        }
        
    }
    
    func nextLevel(_ nextLevel: NextLevel, didProcessRawPhotoCaptureWith photoDict: [String : Any]?, photoConfiguration: NextLevelPhotoConfiguration) {
    }

    func nextLevelDidCompletePhotoCapture(_ nextLevel: NextLevel) {
    }
    
}

// MARK: - KVO

private var CameraViewControllerNextLevelCurrentDeviceObserverContext = "CameraViewControllerNextLevelCurrentDeviceObserverContext"

extension CameraViewController {
    
    internal func addKeyValueObservers() {
        self.addObserver(self, forKeyPath: "currentDevice", options: [.new], context: &CameraViewControllerNextLevelCurrentDeviceObserverContext)
    }
    
    internal func removeKeyValueObservers() {
        self.removeObserver(self, forKeyPath: "currentDevice")
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &CameraViewControllerNextLevelCurrentDeviceObserverContext {
            //self.captureDeviceDidChange()
        }
    }
    
}

