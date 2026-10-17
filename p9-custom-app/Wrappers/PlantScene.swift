//
//  GardenScene.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 13/10/2026.
//

import SwiftUI
import SceneKit

struct PlantScene: UIViewRepresentable {
    var scene: SCNScene
    
    var zoomLevel: Float = 0.9
    var yPadding: Float = 0
    var pitchDegrees: Float = 60
    
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.autoenablesDefaultLighting = true
        setupCamera(for: view)
        return view
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.scene = scene
        setupCamera(for: uiView)
    }
    
    private func setupCamera(for view: SCNView) {
        guard let scene = view.scene else { return }
        
        // Clean up old nodes.
        scene.rootNode.childNodes.filter { $0.name == "cameraPivot" }.forEach { $0.removeFromParentNode() }
        
        let center = scene.rootNode.boundingSphere.center
        let radius = scene.rootNode.boundingSphere.radius > 0 ? scene.rootNode.boundingSphere.radius : 10.0
        
        // Center pivot on the sphere to safely handle rotations.
        let pivot = SCNNode()
        pivot.name = "cameraPivot"
        pivot.position = center
        pivot.eulerAngles = SCNVector3(pitchDegrees * (.pi / 180), 0, 0)
        
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        
        // Scale based on radius to fit any aspect ratio.
        let orthoScale = radius * zoomLevel
        camera.orthographicScale = Double(orthoScale)
        camera.zNear = 0.001
        camera.zFar = Double(radius * 100)
        
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        
        // Calculate bottom alignment.
        let alignY = orthoScale - radius
        
        // Position camera to auto align the bottom.
        cameraNode.position = SCNVector3(0, alignY - (radius * yPadding), radius * 5)
        
        pivot.addChildNode(cameraNode)
        scene.rootNode.addChildNode(pivot)
        view.pointOfView = cameraNode
    }
}
