//
//  GameViewController.swift
//  Orbital
//
//  Created by Ethan Jackwitz on 6/11/17.
//  Copyright © 2017 Ethan Jackwitz. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import ARKit

class GameViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!

    let starNode: SCNNode = {

        let geometry = SCNSphere(radius: 0.3)

        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        material.locksAmbientWithDiffuse = true
        //            material.emission.contents = UIColor.red
        material.selfIllumination.contents = UIColor.red
        geometry.firstMaterial = material


        let node = SCNNode(geometry: geometry)

        node.position = SCNVector3(0, -0.5, -1)

        node.light = SCNLight()
        node.light!.type = .omni

        return node
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.delegate = self

        let planetNode: SCNNode = {

            let geometry = SCNSphere(radius: 0.05)

            let material = SCNMaterial()
            material.diffuse.contents = #imageLiteral(resourceName: "diffuse")
            material.ambient.contents = nil
            material.specular.contents = #imageLiteral(resourceName: "specular")
            material.emission.contents = nil
            material.transparent.contents = nil
            material.reflective.contents = nil
            material.multiply.contents = nil
//            material.normal.contents = #imageLiteral(resourceName: "normal")

            geometry.firstMaterial = material

            let node = SCNNode(geometry: geometry)

            let cloudNode: SCNNode = {

                let geometry = SCNSphere(radius: 0.051)

                geometry.firstMaterial!.transparent.contents = #imageLiteral(resourceName: "clouds")

                return SCNNode(geometry: geometry)
            }()

            node.position = SCNVector3(0.5, -0.5, -1)

            node.addChildNode(cloudNode)


            return node
        }()

        let scene = SCNScene()

        scene.rootNode.addChildNode(starNode)
        scene.rootNode.addChildNode(planetNode)

        planetNode.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 0.2, z: 0.05, duration: 1)))

        // set the scene to the view
        sceneView.scene = scene
        
        // show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // configure the view
        sceneView.backgroundColor = UIColor.black
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal


        sceneView.session.delegate = self
        // Run the view's session
        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        sceneView.session.pause()
    }
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {

        guard let currentFrame = sceneView.session.currentFrame else {
            return
        }
        // check what nodes are tapped
        let p = gestureRecognize.location(in: sceneView)
        let hitResults = sceneView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!

            print(result.node.position)
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
        } else {

            let imagePlane = SCNPlane(width: sceneView.bounds.width / 6000, height: sceneView.bounds.height / 6000)
            imagePlane.firstMaterial?.diffuse.contents = sceneView.snapshot()
            imagePlane.firstMaterial?.lightingModel = .constant

            let planeNode = SCNNode(geometry: imagePlane)
            sceneView.scene.rootNode.addChildNode(planeNode)

            var translation = matrix_identity_float4x4
            translation.columns.3.z = -0.1
            planeNode.simdTransform = matrix_multiply(currentFrame.camera.transform, translation)
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
}

extension GameViewController: ARSCNViewDelegate, ARSessionDelegate {

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        sceneView.backgroundColor = nil
//        if let lightEstimate = frame.lightEstimate {
//            self.starNode.light?.intensity = lightEstimate.ambientIntensity
//        }
    }
}
