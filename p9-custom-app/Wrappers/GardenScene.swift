//
//  GardenScene.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 13/10/2026.
//

import SwiftUI
import SceneKit

struct GardenScene: UIViewRepresentable {
    var scene: SCNScene

    /// How far past the model edge the view can pan. Zero stops at the edge and negative goes tighter.
    var panMargin: Float = -0.3
    /// Most zoomed in. This is the smallest visible half height of the view.
    var minZoomDistance: Float = 0.2
    /// Most zoomed out. This is the largest visible half height of the view.
    var maxZoomDistance: Float = 1
    /// Starting rotation around the model in degrees. Zero looks straight at one side.
    var startAngle: Float = -45
    /// Colour behind the model. Clear shows whatever is behind the view.
    var backgroundColor: Color = .clear
    /// Brightness of the soft light that fills every surface.
    var ambientIntensity: CGFloat = 500
    /// Brightness of the directional sunlight.
    var sunIntensity: CGFloat = 1100

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.autoenablesDefaultLighting = false
        setUpScene(in: scnView, coordinator: context.coordinator)
        applyAppearance(to: scnView, coordinator: context.coordinator)
        applyLimits(to: context.coordinator)
 
        let coordinator = context.coordinator
        let pan = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.maximumNumberOfTouches = 2
        let rotate = UIRotationGestureRecognizer(target: coordinator, action: #selector(Coordinator.handleRotate(_:)))
        let pinch = UIPinchGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePinch(_:)))
 
        let gestures: [UIGestureRecognizer] = [pan, rotate, pinch]
        for gesture in gestures {
            gesture.delegate = coordinator
            scnView.addGestureRecognizer(gesture)
        }
 
        return scnView
    }
 
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Assigning a new scene resets the camera, so the rig must be rebuilt for it.
        if uiView.scene !== scene { setUpScene(in: uiView, coordinator: context.coordinator) }
        applyAppearance(to: uiView, coordinator: context.coordinator)
        applyLimits(to: context.coordinator)
    }
 
    func makeCoordinator() -> Coordinator { Coordinator() }
 
    // Attach the camera rig and lights to the current scene and reset the view.
    private func setUpScene(in scnView: SCNView, coordinator: Coordinator) {
        // Remove the rig from any earlier scene or view so it does not skew the model bounds.
        coordinator.rig.removeFromParentNode()
        scene.rootNode.childNodes.filter { $0.name == "gardenRig" }.forEach { $0.removeFromParentNode() }
        scnView.scene = scene
 
        let (minPoint, maxPoint) = scene.rootNode.boundingBox
        let radius = scene.rootNode.boundingSphere.radius
        let hasBounds = radius > 0
 
        // Use the bounding box for panning because it hugs the model more tightly than a sphere.
        coordinator.modelRadius = hasBounds ? radius : 10
        coordinator.boundsMin = hasBounds ? minPoint : SCNVector3(-10, 0, -10)
        coordinator.boundsMax = hasBounds ? maxPoint : SCNVector3(10, 0, 10)
        let lower = coordinator.boundsMin, upper = coordinator.boundsMax
 
        // Use an orthographic camera and keep it far back so nothing is clipped. Zoom changes the scale.
        let camera = coordinator.camera
        camera.usesOrthographicProjection = true
        camera.orthographicScale = Double(coordinator.modelRadius * 1.5)
        camera.zNear = Double(coordinator.modelRadius * 0.01)
        camera.zFar = Double(coordinator.modelRadius * 100)
        coordinator.cameraNode.position = SCNVector3(0, 0, coordinator.modelRadius * 5)
 
        // Start centred on the model and turned by the start angle.
        coordinator.panPivot.position = SCNVector3((lower.x + upper.x) / 2, (lower.y + upper.y) / 2, (lower.z + upper.z) / 2)
        coordinator.rotatePivot.eulerAngles = SCNVector3(-Float.pi / 4, startAngle * .pi / 180, 0)
 
        scene.rootNode.addChildNode(coordinator.rig)
        scnView.pointOfView = coordinator.cameraNode
    }
 
    // Apply the background colour and light brightness.
    private func applyAppearance(to view: SCNView, coordinator: Coordinator) {
        view.backgroundColor = UIColor(backgroundColor)
        coordinator.ambientLight.intensity = ambientIntensity
        coordinator.sunLight.intensity = sunIntensity
    }
 
    // Pass the latest limits to the coordinator and pull the camera back inside them.
    private func applyLimits(to coordinator: Coordinator) {
        coordinator.panMargin = panMargin
        coordinator.minZoomDistance = minZoomDistance
        coordinator.maxZoomDistance = maxZoomDistance
        coordinator.clampPan()
        coordinator.clampZoom()
    }
 
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        // The rig holds the camera pivots and lights so they can be moved between scenes as one.
        let rig = SCNNode()
        let panPivot = SCNNode()
        let rotatePivot = SCNNode()
        let cameraNode = SCNNode()
        let camera = SCNCamera()
        let ambientLight = SCNLight()
        let sunLight = SCNLight()
        var boundsMin = SCNVector3Zero
        var boundsMax = SCNVector3Zero
        var modelRadius: Float = 10
        var panMargin: Float = 0.25
        var minZoomDistance: Float = 0.2
        var maxZoomDistance: Float = 3
 
        override init() {
            super.init()
            rig.name = "gardenRig"
            cameraNode.camera = camera
            ambientLight.type = .ambient
            sunLight.type = .directional
            sunLight.castsShadow = true
 
            let ambientNode = SCNNode()
            ambientNode.light = ambientLight
            let sunNode = SCNNode()
            sunNode.light = sunLight
            sunNode.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 4, 0)
            sunNode.position = SCNVector3(0, 6, 1)
 
            // Panning moves the pivot and rotating spins the camera around it.
            rotatePivot.addChildNode(cameraNode)
            panPivot.addChildNode(rotatePivot)
            [panPivot, ambientNode, sunNode].forEach { rig.addChildNode($0) }
        }
 
        // Allow pan, rotate and pinch to work together.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
        }
 
        // Keep a value inside a range, using the midpoint if the range has collapsed.
        private func clamp(_ value: Float, _ low: Float, _ high: Float) -> Float {
            low <= high ? Swift.min(Swift.max(value, low), high) : (low + high) / 2
        }
 
        func clampPan() {
            let margin = modelRadius * panMargin
            panPivot.position.x = clamp(panPivot.position.x, boundsMin.x - margin, boundsMax.x + margin)
            panPivot.position.z = clamp(panPivot.position.z, boundsMin.z - margin, boundsMax.z + margin)
        }
 
        func clampZoom() {
            let scale = clamp(Float(camera.orthographicScale), modelRadius * minZoomDistance, modelRadius * maxZoomDistance)
            camera.orthographicScale = Double(scale)
        }
 
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view else { return }
 
            // Convert screen points to scene units using the current zoom.
            let translation = gesture.translation(in: view)
            let unitsPerPoint = Float(camera.orthographicScale) * 2 / Float(view.bounds.height)
            let dx = Float(-translation.x) * unitsPerPoint
            let dz = Float(-translation.y) * unitsPerPoint
 
            // Rotate the movement to match the current camera heading.
            let yaw = rotatePivot.eulerAngles.y
            panPivot.position.x += dx * cos(yaw) + dz * sin(yaw)
            panPivot.position.z += dz * cos(yaw) - dx * sin(yaw)
            clampPan()
 
            gesture.setTranslation(.zero, in: view)
        }
 
        @objc func handleRotate(_ gesture: UIRotationGestureRecognizer) {
            rotatePivot.eulerAngles.y += Float(gesture.rotation)
            gesture.rotation = 0
        }
 
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            let scale = Double(gesture.scale)
            gesture.scale = 1
            guard scale > 0 else { return }
 
            camera.orthographicScale /= scale
            clampZoom()
        }
    }
}
