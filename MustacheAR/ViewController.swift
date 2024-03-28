//
//  ViewController.swift
//  MustacheAR
//  Created by Redwan Khan on 3/25/24.


import UIKit
import SceneKit
import ARKit
import ReplayKit
import simd

struct MustacheStyle {
    let name: String
    let imageName: String
}

class ViewController: UIViewController, ARSCNViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, RPPreviewViewControllerDelegate {
    
    var sceneView: ARSCNView!
    var recordButton: UIButton!
    var mustachesCollectionView: UICollectionView!
    var stopButton: UIButton!
    
    //let mustacheStyles = ["Chevron", "Dali", "English", "Fu Manchu", "Handlebar", "Horseshoe", "Imperial", "Lampshade", "Painter's Brush", "Pencil", "Petit Handlebar", "Pyramidal", "Toothbrush", "Walrus"]
    
    let mustacheStyles = [
//        MustacheStyle(name: "Chevron", imageName: "chevronMustache"),
        MustacheStyle(name: "Dali", imageName: "dali"),
        MustacheStyle(name: "default", imageName: "defaultMustache")
    ]

    
    
    
   // let mustacheStyles = ["mustacheImage"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupARSession()
    }
    
    func setupUI() {
        // Scene View Setup
        sceneView = ARSCNView(frame: self.view.bounds)
        self.view.addSubview(sceneView)
        
        // Record Button Setup
        recordButton = UIButton(frame: CGRect(x: 20, y: self.view.frame.height - 100, width: 120, height: 50))
        recordButton.backgroundColor = .red
        recordButton.setTitle("Record", for: .normal)
        recordButton.addTarget(self, action: #selector(startRecording), for: .touchUpInside)
        self.view.addSubview(recordButton)
        
        // Stop Button Setup
        stopButton = UIButton(frame: CGRect(x: self.view.frame.width - 140, y: self.view.frame.height - 100, width: 120, height: 50))
        stopButton.backgroundColor = .gray
        stopButton.setTitle("Stop", for: .normal)
        stopButton.addTarget(self, action: #selector(stopRecording), for: .touchUpInside)
        self.view.addSubview(stopButton)
        
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
    
    func setupARSession() {
        sceneView.delegate = self
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    // ReplayKit recorder instance
    let recorder = RPScreenRecorder.shared()

    @objc func startRecording() {
        guard recorder.isAvailable else {
            print("Recording is not available at this time.")
            return
        }

        recorder.startRecording { [weak self] (error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to start recording: \(error.localizedDescription)")
                    // Handle the error condition
                } else {
                    print("Started recording successfully")
                    // Update UI to indicate recording
                    //self?.showRecordingIndicator()
                    self?.recordButton.backgroundColor = .gray
                    self?.recordButton.setTitle("Recording...", for: .normal)
                    self?.stopButton.isEnabled = true
                }
            }
        }
    }

    @objc func stopRecording() {
        recorder.stopRecording { [weak self] (previewController, error) in
            DispatchQueue.main.async {
                self?.recordButton.isEnabled = true
                self?.stopButton.isEnabled = false

                // Revert UI changes made at the start of recording
                self?.recordButton.backgroundColor = .red
                self?.recordButton.setTitle("Record", for: .normal)
                //self?.hideRecordingIndicator()

                if let error = error {
                    print("Failed to stop recording: \(error.localizedDescription)")
                    //FIXME: Handle the error condition
                } else {
                    print("Stopped recording successfully")
                    // FIXME: Optionally preview the recording
                    if let previewController = previewController {
                        previewController.previewControllerDelegate = self
                        self?.present(previewController, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
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
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mustacheStyles.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MustacheCell", for: indexPath)
        
        let mustacheStyle = mustacheStyles[indexPath.row]
        let imageView = UIImageView(frame: cell.bounds)
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: mustacheStyle.imageName)
        cell.contentView.addSubview(imageView)
        
        return cell
    }


    
    var currentMustacheImageName: String?


    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
    
    
//    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
//        
//        let mouthCloseValue = faceAnchor.blendShapes[.mouthClose] as? Float ?? 0.0
//           let noseSneerLeft = faceAnchor.blendShapes[.noseSneerLeft] as? Float ?? 0.0
//           let noseSneerRight = faceAnchor.blendShapes[.noseSneerRight] as? Float ?? 0.0
//        
//        let noseTipPosition = faceAnchor.geometry.vertices[noseTipIndex]
//        let upperLipPosition = faceAnchor.geometry.vertices[upperLipIndex]
//        
//        // Calculate the midpoint or desired position between the nose and upper lip
//        let mustachePosition = calculateMustachePosition(noseTip: noseTipPosition, upperLip: upperLipPosition)
//        
//        // Update the mustache's position
//        DispatchQueue.main.async {
//            self.updateMustachePosition(mustachePosition)
//        }
//    }


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
 



    



    
    func previewController(_ previewController: RPPreviewViewController, didFinishWithActivityTypes activityTypes: Set<String>) {
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








