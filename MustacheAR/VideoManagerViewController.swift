//
//  VideoManagerViewController.swift
//  MustacheAR
//
//  Created by Redwan Khan on 3/28/24.
//

import UIKit
import Photos
class VideoManagerViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
   

    func saveVideoToAppStorage(temporaryURL: URL) {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let newVideoURL = documentsDirectory.appendingPathComponent("\(UUID().uuidString).mov")

        do {
            try fileManager.moveItem(at: temporaryURL, to: newVideoURL)
            // Now you can save newVideoURL.path as the path of your video in Core Data
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

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
