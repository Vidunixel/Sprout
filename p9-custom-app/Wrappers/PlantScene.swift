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
    
    var allowHorizontalRotation: Bool = false
    var autoRotate: Bool = false
    
    var zoomLevel: Float = 0.85
    var yPadding: Float = 0
    var pitchDegrees: Float = 60
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.autoenablesDefaultLighting = true
        
        // Clone scene.
        let isolatedScene = SCNScene()
        let clonedRoot = scene.rootNode.clone()
        isolatedScene.rootNode.addChildNode(clonedRoot)
        view.scene = isolatedScene
        
        // Setup camera.
        setupCamera(for: view)
        
        // Add pan gesture.
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        context.coordinator.panGesture = panGesture
        view.addGestureRecognizer(panGesture)
        
        return view
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Update parent ref.
        context.coordinator.parent = self
        
        // Toggle gesture.
        context.coordinator.panGesture?.isEnabled = allowHorizontalRotation
        
        if let yawPivot = uiView.scene?.rootNode.childNode(withName: "yawPivot", recursively: false) {
            // Toggle auto rotate.
            if autoRotate {
                // Check if animating.
                if yawPivot.action(forKey: "autoRotate") == nil {
                    // Spin around Z.
                    let rotate = SCNAction.rotateBy(x: 0, y: 0, z: .pi * 2, duration: 20)
                    yawPivot.runAction(.repeatForever(rotate), forKey: "autoRotate")
                }
            } else {
                yawPivot.removeAction(forKey: "autoRotate")
            }
        }
    }
    
    private func setupCamera(for view: SCNView) {
        guard let scene = view.scene else { return }
        
        // Clean old nodes.
        scene.rootNode.childNodes.filter { $0.name == "yawPivot" }.forEach { $0.removeFromParentNode() }
        
        let (min, max) = scene.rootNode.boundingBox
        let center = SCNVector3((min.x + max.x) / 2, (min.y + max.y) / 2, (min.z + max.z) / 2)
        
        let dx = max.x - center.x
        let dy = max.y - center.y
        let dz = max.z - center.z
        let radius = Float(sqrt(dx*dx + dy*dy + dz*dz))
        let safeRadius = radius > 0 ? radius : 10.0
        
        // Yaw pivot.
        let yawPivot = SCNNode()
        yawPivot.name = "yawPivot"
        yawPivot.position = center
        
        // Pitch pivot.
        let pitchPivot = SCNNode()
        pitchPivot.name = "pitchPivot"
        pitchPivot.eulerAngles = SCNVector3(pitchDegrees * (.pi / 180), 0, 0)
        
        yawPivot.addChildNode(pitchPivot)
        
        let camera = SCNCamera()
        camera.usesOrthographicProjection = true
        
        let orthoScale = safeRadius * zoomLevel
        camera.orthographicScale = Double(orthoScale)
        camera.zNear = 0.001
        camera.zFar = Double(safeRadius * 100)
        
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        
        scene.rootNode.addChildNode(yawPivot)
        
        let corners = [
            SCNVector3(min.x, min.y, min.z), SCNVector3(min.x, min.y, max.z),
            SCNVector3(min.x, max.y, min.z), SCNVector3(min.x, max.y, max.z),
            SCNVector3(max.x, min.y, min.z), SCNVector3(max.x, min.y, max.z),
            SCNVector3(max.x, max.y, min.z), SCNVector3(max.x, max.y, max.z)
        ]
        
        var lowestY: Float = .greatestFiniteMagnitude
        for corner in corners {
            // Convert to pitch space.
            let localCorner = pitchPivot.convertPosition(corner, from: scene.rootNode)
            if localCorner.y < lowestY {
                lowestY = localCorner.y
            }
        }
        
        let alignY = orthoScale + lowestY
        cameraNode.position = SCNVector3(0, alignY - (safeRadius * yPadding), safeRadius * 5)
        
        pitchPivot.addChildNode(cameraNode)
        view.pointOfView = cameraNode
    }
    
    final class Coordinator: NSObject {
        var parent: PlantScene
        var panGesture: UIPanGestureRecognizer?
        var initialEulerZ: Float = 0
        
        init(parent: PlantScene) {
            self.parent = parent
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view as? SCNView,
                  let yawPivot = view.scene?.rootNode.childNode(withName: "yawPivot", recursively: false) else { return }
            
            let translation = gesture.translation(in: view)
            
            switch gesture.state {
            case .began:
                // Pause auto rotate.
                yawPivot.removeAction(forKey: "autoRotate")
                initialEulerZ = yawPivot.eulerAngles.z
                
            case .changed:
                // Invert drag speed.
                let panX = Float(translation.x) * -0.01
                yawPivot.eulerAngles.z = initialEulerZ + panX
                
            case .ended, .cancelled:
                // Resume auto rotate.
                if parent.autoRotate {
                    let rotate = SCNAction.rotateBy(x: 0, y: 0, z: .pi * 2, duration: 20)
                    yawPivot.runAction(.repeatForever(rotate), forKey: "autoRotate")
                }
            default:
                break
            }
        }
    }
}
