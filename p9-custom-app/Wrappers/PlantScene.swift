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
    
    var zoomLevel: Float = 0.85
    var yPadding: Float = -0.1
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
        
        // Clean old nodes.
        scene.rootNode.childNodes.filter { $0.name == "cameraPivot" }.forEach { $0.removeFromParentNode() }
        
        // Get box instead of sphere.
        let (min, max) = scene.rootNode.boundingBox
        let center = SCNVector3((min.x + max.x) / 2, (min.y + max.y) / 2, (min.z + max.z) / 2)
        
        // Calc radius to fit on screen.
        let dx = max.x - center.x
        let dy = max.y - center.y
        let dz = max.z - center.z
        let radius = Float(sqrt(dx*dx + dy*dy + dz*dz))
        let safeRadius = radius > 0 ? radius : 10.0
        
        let pivot = SCNNode()
        pivot.name = "cameraPivot"
        pivot.position = center
        pivot.eulerAngles = SCNVector3(pitchDegrees * (.pi / 180), 0, 0)
        
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        
        let orthoScale = safeRadius * zoomLevel
        camera.orthographicScale = Double(orthoScale)
        camera.zNear = 0.001
        camera.zFar = Double(safeRadius * 100)
        
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        
        // Add early for coords.
        scene.rootNode.addChildNode(pivot)
        
        // Find visual bottom.
        let corners = [
            SCNVector3(min.x, min.y, min.z),
            SCNVector3(min.x, min.y, max.z),
            SCNVector3(min.x, max.y, min.z),
            SCNVector3(min.x, max.y, max.z),
            SCNVector3(max.x, min.y, min.z),
            SCNVector3(max.x, min.y, max.z),
            SCNVector3(max.x, max.y, min.z),
            SCNVector3(max.x, max.y, max.z)
        ]
        
        var lowestY: Float = .greatestFiniteMagnitude
        for corner in corners {
            // Convert to local space.
            let localCorner = pivot.convertPosition(corner, from: scene.rootNode)
            if localCorner.y < lowestY {
                lowestY = localCorner.y
            }
        }
        
        // Align frame to lowest point.
        let alignY = orthoScale + lowestY
        
        cameraNode.position = SCNVector3(0, alignY - (safeRadius * yPadding), safeRadius * 5)
        
        pivot.addChildNode(cameraNode)
        view.pointOfView = cameraNode
    }
}
