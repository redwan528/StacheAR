//
//  RecordingsListViewController.swift
//  MustacheAR
//
//  Created by Redwan Khan on 3/28/24.
//

import UIKit
import CoreData
import AVFoundation

class RecordingsListViewController: UITableViewController {
    var recordings: [RecordedVideo] = []

//    override func viewDidLoad() {
//        super.viewDidLoad()
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
//        fetchRecordings()
//    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(fetchRecordings), name: NSNotification.Name("NewRecordingSaved"), object: nil)
        fetchRecordings()
    }
    
    

    func generateThumbnail(for url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        let time = CMTimeMakeWithSeconds(1.0, preferredTimescale: 600)
        do {
            let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: img)
        } catch {
            print("Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }


    @objc func fetchRecordings() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<RecordedVideo> = RecordedVideo.fetchRequest()

        do {
            recordings = try managedContext.fetch(fetchRequest)
            tableView.reloadData()
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recordings.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let recording = recordings[indexPath.row]
        cell.textLabel?.text = recording.tag // Customize as needed
        return cell
    }
    
    // to remove the observer when the view controller is deinitialized
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
