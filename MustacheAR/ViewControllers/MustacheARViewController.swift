//
//  ViewController.swift
//  MustacheAR
//  Created by Redwan Khan on 3/25/24.


import UIKit
import SceneKit
import ARKit
import ReplayKit
import simd
import Photos
import AVFoundation

struct MustacheStyle {
    let name: String
    let imageName: String
}

class MustacheARViewController: UIViewController, ARSCNViewDelegate
, UICollectionViewDataSource, UICollectionViewDelegate, RPPreviewViewControllerDelegate /*,UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, RPPreviewViewControllerDelegate */{
    
    var sceneView: ARSCNView!
    var recordButton: UIButton!
    var mustachesCollectionView: UICollectionView!
    var stopButton: UIButton!
    var isRecording = false

    
    
    let videoManager = VideoManager()

    
    let mustacheStyles = [
//        MustacheStyle(name: "Chevron", imageName: "chevronMustache"),
        MustacheStyle(name: "Dali", imageName: "dali"),
        MustacheStyle(name: "default", imageName: "defaultMustache")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupARSession()
        videoManager.checkPermissions()
        setupRecorderButton()
        setupGalleryButton()
        mustacheSelectionView()

    }
    func setupRecorderButton(){
        // Recorder setup
        recordButton = UIButton(frame: CGRect(x: (self.view.frame.width - 120) / 2, y: self.view.frame.height - 80, width: 120, height: 50))
        recordButton.backgroundColor = .systemRed
        recordButton.setTitle("Record", for: .normal)
        
        recordButton.layer.cornerRadius = 25 // Rounded corners
       
        recordButton.setTitleColor(.white, for: .normal)
        recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        self.view.addSubview(recordButton)
    }

    
    func mustacheSelectionView(){
        // Mustaches CollectionView Setup
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        mustachesCollectionView = UICollectionView(frame: CGRect(x: 0, y: self.view.frame.height - 150, width: self.view.frame.width, height: 50), collectionViewLayout: layout)
        mustachesCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "MustacheCell")
        mustachesCollectionView.backgroundColor = .white
        mustachesCollectionView.dataSource = self
        mustachesCollectionView.delegate = self
        self.view.addSubview(mustachesCollectionView)
    }
    
    func setupUI() {
        // Scene View Setup
        sceneView = ARSCNView(frame: self.view.bounds)
        self.view.addSubview(sceneView)

    }
 
    func setupARSession() {
        sceneView.delegate = self
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    // ReplayKit recorder instance
    let recorder = RPScreenRecorder.shared()


    
    var recordingIndicator: UIView?

    func showRecordingIndicator() {
        let indicator = UIView(frame: CGRect(x: self.view.frame.width - 60, y: 30, width: 20, height: 20))
        indicator.layer.cornerRadius = 10
        indicator.backgroundColor = .red
        self.view.addSubview(indicator)
        self.recordingIndicator = indicator

        // Blink animation
        let blinkAnimation = CABasicAnimation(keyPath: "opacity")
        blinkAnimation.fromValue = 1.0
        blinkAnimation.toValue = 0.1
        blinkAnimation.duration = 0.8
        blinkAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        blinkAnimation.autoreverses = true
        blinkAnimation.repeatCount = Float.infinity
        indicator.layer.add(blinkAnimation, forKey: "blinking")
    }

    func hideRecordingIndicator() {
        recordingIndicator?.layer.removeAllAnimations()
        recordingIndicator?.removeFromSuperview()
    }




    
    // UICollectionViewDataSource Methods
    @objc func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mustacheStyles.count
    }

    @objc(collectionView:cellForItemAtIndexPath:) func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MustacheCell", for: indexPath)
        
        let mustacheStyle = mustacheStyles[indexPath.row]
        let imageView = UIImageView(frame: cell.bounds)
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: mustacheStyle.imageName)
        cell.contentView.addSubview(imageView)
        
        return cell
    }


    
    var currentMustacheImageName: String?


    
    @objc(collectionView:didSelectItemAtIndexPath:) func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedStyle = mustacheStyles[indexPath.row]
        currentMustacheImageName = selectedStyle.imageName

        // Force the scene to refresh
        refreshMustacheNode()
    }

    func refreshMustacheNode() {
        guard let configuration = sceneView.session.configuration else { return }
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }


    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        let noseTipIndex = 9 // only a temp example
        let noseTipPosition = faceAnchor.geometry.vertices[noseTipIndex]
        
        let mustacheNodeName = "mustacheNode"
        if let mustacheNode = node.childNode(withName: mustacheNodeName, recursively: true) {
            // Position the mustache relative to the nose tip
            let xOffset: Float = 0 // Adjust as necessary
            let yOffset: Float = -0.03 // Move the mustache slightly below the nose tip
            let zOffset: Float = -0.05 // Adjust based on the depth
            
            mustacheNode.simdPosition = simd_make_float3(noseTipPosition.x + xOffset, noseTipPosition.y + yOffset, noseTipPosition.z + zOffset)
   
            
            // Inside renderer(_:didUpdate:for:):
            } else {
                // correctly creates and add a new mustache node if it doesn't exist.
                let newMustacheNode = createMustacheNode(with: currentMustacheImageName ?? "defaultMustache") // Fallback to "defaultMustache"
                newMustacheNode.name = mustacheNodeName
                node.addChildNode(newMustacheNode)
            }

        }

    func createMustacheNode(with imageName: String) -> SCNNode {
        guard let image = UIImage(named: imageName) else {
            fatalError("Failed to load image: \(imageName)")
        }
        let mustacheGeometry = SCNPlane(width: 0.1, height: 0.1)
        mustacheGeometry.firstMaterial?.diffuse.contents = image
        let mustacheNode = SCNNode(geometry: mustacheGeometry)
       
        return mustacheNode
    }


  

    
    func updateMustacheNode(with imageName: String) {
        guard let image = UIImage(named: imageName) else {
            print("Failed to load the image: \(imageName)")
            return
        }

        let mustacheNodeName = "mustacheNode"
        let mustacheNode: SCNNode
        if let existingNode = sceneView.scene.rootNode.childNode(withName: mustacheNodeName, recursively: true) {
            // Update the existing node's image
            mustacheNode = existingNode
        } else {
            // Create a new mustache node and add it to the scene
            mustacheNode = createMustacheNode(with: imageName)
            mustacheNode.name = mustacheNodeName
            //  method to correctly position this node on the face
            // For example, adding it to a face anchor node in the ARSCNViewDelegate method
        }

        if let geometry = mustacheNode.geometry as? SCNPlane {
            geometry.firstMaterial?.diffuse.contents = image
        }
    }

    
    @objc func previewController(_ previewController: RPPreviewViewController, didFinishWithActivityTypes activityTypes: Set<String>) {
            if activityTypes.contains(UIActivity.ActivityType.saveToCameraRoll.rawValue) {
                // The video was saved to the Photos gallery
                DispatchQueue.main.async {
                    self.showSaveConfirmationAlert()
                }
            }
            previewController.dismiss(animated: true, completion: nil)
        }
        
        func showSaveConfirmationAlert() {
            let alert = UIAlertController(title: "Saved", message: "Your video has been saved to your gallery.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                // User acknowledged the save, you can perform additional actions here if needed
            }
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    
    private let galleryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Gallery", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        return button
    }()

    
    @objc func galleryButtonTapped() {
        let recordingsListVC = RecordingsListViewController()
        navigationController?.pushViewController(recordingsListVC, animated: true)
    }



    
    private func setupGalleryButton() {
        view.addSubview(galleryButton)

        // Disable autoresizing mask constraints
        galleryButton.translatesAutoresizingMaskIntoConstraints = false

        let safeArea = view.safeAreaLayoutGuide

        // Constraints
        NSLayoutConstraint.activate([
            galleryButton.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: 0), // Adjust the constant for margin from bottom
            galleryButton.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -20), // Adjust the constant for margin from right
            galleryButton.widthAnchor.constraint(equalToConstant: 100), // Set your desired width
            galleryButton.heightAnchor.constraint(equalToConstant: 50) // Set your desired height
        ])

        // Add tap action
        galleryButton.addTarget(self, action: #selector(galleryButtonTapped), for: .touchUpInside)
    }
    
    //OG working one
//    @objc func toggleRecording() {
//        if isRecording {
//            // Stop Recording
//            recorder.stopRecording { [weak self] (previewController, error) in
//                DispatchQueue.main.async {
//                    guard let strongSelf = self else { return }
//
//                    if let error = error {
//                        print("Failed to stop recording: \(error.localizedDescription)")
//                    } else {
//                        print("Stopped recording successfully")
//                        if let previewController = previewController {
//                            previewController.previewControllerDelegate = strongSelf
//                            strongSelf.present(previewController, animated: true, completion: nil)
//                        }
//
//
//                    }
//
//                    // UI updates to indicate that recording has stopped
//                    strongSelf.recordButton.backgroundColor = .red
//                    strongSelf.recordButton.setTitle("Record", for: .normal)
//                    strongSelf.isRecording = false
//
//                    // Show UI elements again
//                    strongSelf.mustachesCollectionView.isHidden = false
//                    // Add any other UI elements you want to show again
//                }
//            }
//        } else {
//            // Start Recording
//            guard recorder.isAvailable else {
//                print("Recording is not available at this time.")
//                return
//            }
//
//            // Hide UI elements
//            mustachesCollectionView.isHidden = true
//            // Add any other UI elements you want to hide
//
//            recorder.startRecording { [weak self] (error) in
//                DispatchQueue.main.async {
//                    if let error = error {
//                        print("Failed to start recording: \(error.localizedDescription)")
//                    } else {
//                        print("Started recording successfully")
//                    }
//
//                    // UI updates to indicate that recording has started
//                    self?.recordButton.backgroundColor = .gray
//                    self?.recordButton.setTitle("Stop", for: .normal)
//                    self?.isRecording = true
//                }
//            }
//        }
//    }
    
    //MARK: one that works with tag prompt
    @objc func toggleRecording() {
        if isRecording {
            // Stop Recording
            recorder.stopRecording { [weak self] (previewController, error) in
                DispatchQueue.main.async {
                    guard let self = self else { return }

                    if let error = error {
                        print("Failed to stop recording: \(error.localizedDescription)")
                        return
                    }

                    self.isRecording = false
                    self.updateUIForRecordingStopped()

                    // Prompt for tagging
                    let alertController = UIAlertController(title: "Tag your video", message: "Enter a tag for your recording:", preferredStyle: .alert)
                    
                    alertController.addTextField { textField in
                        textField.placeholder = "Tag"
                    }
                    
                    let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
                        guard let tag = alertController.textFields?.first?.text, !tag.isEmpty else {
                            print("Tag is empty.")
                            return
                        }
                        
                        // Save metadata. Here, just the tag is saved since we don't have direct video file access
                        self.saveRecordingMetadata(tag: tag)

                        // Optionally, present the preview controller after tagging
                        if let previewController = previewController {
                            previewController.previewControllerDelegate = self
                            self.present(previewController, animated: true, completion: nil)
                        }
                    }
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                        // Handle cancellation here
                    }
                    
                    alertController.addAction(saveAction)
                    alertController.addAction(cancelAction)
                    
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        } else {
            // Start Recording
            if recorder.isAvailable {
                recorder.startRecording { [weak self] (error) in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("Failed to start recording: \(error.localizedDescription)")
                        } else {
                            print("Started recording successfully")
                            self?.isRecording = true
                            self?.updateUIForRecordingStarted()
                        }
                    }
                }
            } else {
                print("Recording is not available at this time.")
            }
        }
    }
    
    //MARK: Beta
//    @objc func toggleRecording() {
//        if isRecording {
//            // Assuming videoManager is an instance of VideoManager available in this class
//            videoManager.stopRecording { [weak self] (videoURL, error) in
//                DispatchQueue.main.async {
//                    guard let self = self, let videoURL = videoURL else {
//                        print("Error stopping recording or video URL not found: \(String(describing: error))")
//                        return
//                    }
//
//                    self.isRecording = false
//                    self.updateUIForRecordingStopped()
//
//                    // Prompt for tagging
//                    let alertController = UIAlertController(title: "Tag your video", message: "Enter a tag for your recording:", preferredStyle: .alert)
//                    alertController.addTextField { textField in
//                        textField.placeholder = "Tag"
//                    }
//                    
//                    let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
//                        guard let tag = alertController.textFields?.first?.text, !tag.isEmpty else {
//                            print("Tag is empty.")
//                            return
//                        }
//                        
//                        // Calculate the duration of the video
//                        let duration = self.videoManager.calculateVideoDuration(url: videoURL)
//                        
//                        // Save the recording details including the tag
//                        self.videoManager.saveRecording(url: videoURL, duration: duration, tag: tag)
//                        
//                        // Refresh the recordings list in case the RecordingsListViewController is already loaded
//                        NotificationCenter.default.post(name: NSNotification.Name("NewRecordingSaved"), object: nil)
//                    }
//                    
//                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
//                    alertController.addAction(saveAction)
//                    alertController.addAction(cancelAction)
//                    self.present(alertController, animated: true, completion: nil)
//                }
//            }
//        } else {
//            // Start Recording
//            if recorder.isAvailable {
//                recorder.startRecording { [weak self] (error) in
//                    DispatchQueue.main.async {
//                        if let error = error {
//                            print("Failed to start recording: \(error.localizedDescription)")
//                        } else {
//                            print("Started recording successfully")
//                            self?.isRecording = true
//                            self?.updateUIForRecordingStarted()
//                        }
//                    }
//                }
//            } else {
//                print("Recording is not available at this time.")
//            }
//        }
//    }


    private func updateUIForRecordingStopped() {
        recordButton.backgroundColor = .red
        recordButton.setTitle("Record", for: .normal)
        mustachesCollectionView.isHidden = false
    }

    private func updateUIForRecordingStarted() {
        recordButton.backgroundColor = .gray
        recordButton.setTitle("Stop", for: .normal)
        mustachesCollectionView.isHidden = true
    }

    private func saveRecordingMetadata(tag: String) {
        print("Saving recording with tag: \(tag)")
    }
    func saveRecording(url: URL, duration: Double, tag: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("Could not get AppDelegate")
            return
        }
        let context = appDelegate.persistentContainer.viewContext

        let newRecording = RecordedVideo(context: context)
        newRecording.fileName = url.lastPathComponent
        newRecording.duration = duration
        newRecording.tag = tag
        newRecording.dateRecorded = Date()

        do {
            try context.save()
            print("Recording saved with tag: \(tag)")
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }


    
    
    
    
    
    


    
    
}
// Extension to convert simd_float4x4 to Euler angles
extension SCNMatrix4 {
    func toEulerAngles() -> SCNVector3 {
        // This is a simplified way to extract Euler angles from a rotation matrix
        let x = atan2(-m32, m33)
        let y = atan2(m31, sqrt(m32 * m32 + m33 * m33))
        let z = atan2(-m21, m11)
        return SCNVector3(x, y, z)
        
        

    }
}


extension simd_float4x4 {
    func toEulerAngles() -> (roll: Float, pitch: Float, yaw: Float) {
        // Extract the pitch, yaw, and roll from the matrix
        let pitch = atan2(-self[2][0], sqrt(self[0][0] * self[0][0] + self[1][0] * self[1][0]))
        let yaw = atan2(self[1][0], self[0][0])
        let roll = atan2(self[2][1], self[2][2])

        return (roll, pitch, yaw)
    }
}









