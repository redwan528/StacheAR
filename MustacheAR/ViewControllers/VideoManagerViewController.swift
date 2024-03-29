//
//  VideoManagerViewController.swift
//  MustacheAR
//
//  Created by Redwan Khan on 3/28/24.
//

import UIKit
import Photos
import CoreData
class VideoManager: NSObject, AVCaptureFileOutputRecordingDelegate {
    var captureSession: AVCaptureSession?
    var videoOutput: AVCaptureMovieFileOutput?
    var currentVideoURL: URL?
    var recordingStartTime: Date?
    // Add a property to store the completion handler
    var stopRecordingCompletion: ((URL?, Error?) -> Void)?

    override init() {
        super.init()
        checkAndStartSession()
    }
    

    
    func calculateVideoDuration(url: URL) -> Double {
        let asset = AVURLAsset(url: url)
        return CMTimeGetSeconds(asset.duration)
    }


    func saveRecording(url: URL, duration: Double, tag: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newRecording = RecordedVideo(context: context)
        newRecording.fileName = url.lastPathComponent
        newRecording.duration = duration
        newRecording.tag = tag
        newRecording.dateRecorded = Date()
        
        do {
            try context.save()
        } catch {
            print("Failed to save recording: \(error)")
        }
    }
    

    
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break // Already authorized
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    print("Camera access denied")
                }
            }
        default:
            print("Camera access denied")
            return
        }
        
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            break // Already authorized
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if !granted {
                    print("Microphone access denied")
                }
            }
        default:
            print("Microphone access denied")
            return
        }
    }
    
    func setupCaptureSession() {
        // Initialize the capture session and setup input (camera) and output (file)
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession else { return }
        
        if let device = AVCaptureDevice.default(for: .video),
           let input = try? AVCaptureDeviceInput(device: device),
           captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        videoOutput = AVCaptureMovieFileOutput()
        if let videoOutput = videoOutput, captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
    }
    func checkAndStartSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.checkPermissions() // This will request permissions if not determined
            self?.setupCaptureSession() // Setup and configure the session
            self?.captureSession?.startRunning() // Start the session
        }
    }

    
    func startRecording() {
        guard let captureSession = captureSession, captureSession.isRunning else {
            print("Capture session is not running.")
            return
        }
        
        _ = FileManager.default
        let tempDir = NSTemporaryDirectory()
        let filePath = (tempDir as NSString).appendingPathComponent("\(UUID().uuidString).mov")
        currentVideoURL = URL(fileURLWithPath: filePath)
        
        if let videoOutput = videoOutput, !videoOutput.isRecording {
            videoOutput.startRecording(to: currentVideoURL!, recordingDelegate: self)
            print("Started recording to: \(currentVideoURL!.absoluteString)")
        }
    }
    


    func saveRecording(fileName: String, duration: Double, tag: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        // Create a new recorded video object using the subclass
        let video = RecordedVideo(context: managedContext)
        
        // Set the attribute values directly
        video.fileName = fileName
        video.duration = duration
        video.tag = tag
        video.dateRecorded = Date()
        
        
        // Attempt to save the object
        do {
            try managedContext.save()
            print("Successfully saved the video!")
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }


    
   

    func saveVideoToAppStorage(temporaryURL: URL) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let newVideoURL = documentsDirectory.appendingPathComponent("\(UUID().uuidString).mov")

        do {
            try fileManager.moveItem(at: temporaryURL, to: newVideoURL)
            // save newVideoURL.path as the path of your video in Core Data
        } catch {
            print("Error saving video to app storage: \(error)")
        }
    }

    func saveVideoToPhotoGallery(videoURL: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                UISaveVideoAtPathToSavedPhotosAlbum(videoURL.path, self, #selector(self.video(_:didFinishSavingWithError:contextInfo:)), nil)
            }
        }
    }

    @objc func video(_ videoPath: String, didFinishSavingWithError error: Error?, contextInfo: UnsafeMutableRawPointer?) {
        if let error = error {
            print("Error saving video to gallery: \(error)")
        } else {
            print("Video saved to gallery successfully")
        }
    }
    
    
    func stopRecording(completion: @escaping (URL?, Error?) -> Void) {
        guard let videoOutput = videoOutput, videoOutput.isRecording else {
            completion(nil, NSError(domain: "VideoManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not recording"]))
            return
        }
        
        videoOutput.stopRecording() // This triggers the delegate method which should handle the rest
    }

    // AVCaptureFileOutputRecordingDelegate method
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording video: \(error.localizedDescription)")
            stopRecordingCompletion?(nil, error)
        } else {
            print("Recording finished: \(outputFileURL.absoluteString)")
            stopRecordingCompletion?(outputFileURL, nil)
        }
        
        // Reset the completion handler
        stopRecordingCompletion = nil
    }
    
    
//MARK: Beta
//    func stopRecording(completion: @escaping (URL?, Error?) -> Void) {
//        guard let videoOutput = videoOutput, videoOutput.isRecording else {
//            completion(nil, NSError(domain: "VideoManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not recording"]))
//            return
//        }
//
//        stopRecordingCompletion = completion // Store the passed completion handler
//        videoOutput.stopRecording() // This will eventually trigger the delegate method
//    }
//
//    // Delegate method handling the end of recording
//    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
//        if let error = error {
//            print("Error recording video: \(error.localizedDescription)")
//            stopRecordingCompletion?(nil, error)
//        } else {
//            print("Recording finished successfully")
//            stopRecordingCompletion?(outputFileURL, nil)
//        }
//        
//        //  reset the completion handler to nil
//        stopRecordingCompletion = nil
//    }



    // Adjust saveVideoToAppStorage to return the new URL
    func saveVideoToAppStorage(temporaryURL: URL) -> URL {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let newVideoURL = documentsDirectory.appendingPathComponent(UUID().uuidString + ".mov")
        
        do {
            try fileManager.moveItem(at: temporaryURL, to: newVideoURL)
            print("Video moved to app storage: \(newVideoURL.absoluteString)")
            return newVideoURL
        } catch {
            print("Error saving video to app storage: \(error)")
            // Handle error, potentially return temporaryURL or a specific error URL
            return temporaryURL
        }
    }



}
