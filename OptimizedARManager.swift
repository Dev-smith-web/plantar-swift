import Foundation
import SwiftUI
import ARKit
import RealityKit
import Combine

// MARK: - AR Logic Manager

class OptimizedARManager: NSObject, ARSessionDelegate, ObservableObject {
    @Published var modelLoaded = false
    @Published var isLoading = false
    @Published var trackingState: ARCamera.TrackingState = .notAvailable
    @Published var error: String? = nil
    
    var arSession = ARSession()
    var arView: ARView?
    
    private var currentAnchor: AnchorEntity?
    private var currentModelEntity: ModelEntity?
    private var currentPivotEntity: Entity?
    
    private var startTime: Date = Date()
    private var timeSpentTimer: Timer?
    
    override init() {
        super.init()
        arSession.delegate = self
    }
    
    deinit {
        timeSpentTimer?.invalidate()
    }
    
    /// Initializes the AR session to look for specific plant reference images
    func setupAR(for plant: Plant) {
        let configuration = ARImageTrackingConfiguration()
        
        // Attempt to load the reference image group from Assets
        if let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "PlantCards", bundle: nil) {
            configuration.trackingImages = referenceImages
            configuration.maximumNumberOfTrackedImages = 1
        } else {
            self.error = "AR Reference images missing from project assets."
        }
        
        arSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    /// Asynchronously loads the 3D USDZ model onto a detected image anchor
    func loadPlantModelAsync(_ plant: Plant, on anchor: ARImageAnchor, in arView: ARView) {
        // Prevent double-loading
        guard !isLoading && !modelLoaded else { return }
        
        self.isLoading = true
        self.startTime = Date()
        
        // We use a background task to prevent the UI from "hitching"
        // while the heavy 3D file is being decrypted and parsed.
        Task(priority: .userInitiated) {
            do {
                // RealityKit's standard synchronous load is safe here because we are in a background Task
                let modelEntity = try ModelEntity.loadModel(named: plant.modelName)
                
                await MainActor.run {
                    self.setupScene(with: modelEntity, for: plant, on: anchor, in: arView)
                }
            } catch {
                await MainActor.run {
                    self.error = "Could not find \(plant.modelName) in the app bundle."
                    self.isLoading = false
                    print("AR Load Error: \(error)")
                }
            }
        }
    }
    
    private func setupScene(with model: ModelEntity, for plant: Plant, on anchor: ARImageAnchor, in arView: ARView) {
        let anchorEntity = AnchorEntity(anchor: anchor)
        let pivot = Entity() // Pivot allows rotation without affecting the anchor
        pivot.position = [0, 0, 0]
        
        // Apply plant-specific offsets from our Database
        model.position.y = plant.yOffset
        model.position.x = plant.xOffset
        model.scale = [plant.scale, plant.scale, plant.scale]
        
        pivot.addChild(model)
        anchorEntity.addChild(pivot)
        arView.scene.addAnchor(anchorEntity)
        
        self.currentAnchor = anchorEntity
        self.currentModelEntity = model
        self.currentPivotEntity = pivot
        self.modelLoaded = true
        self.isLoading = false
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        startTimeTracking()
    }
    
    // MARK: - Interactions
    
    func applyRotation(_ rotation: Float) {
        guard let pivot = currentPivotEntity else { return }
        pivot.orientation = simd_quatf(angle: rotation, axis: [0, 1, 0]) * pivot.orientation
    }
    
    func applyZoom(_ scale: Float, plant: Plant) {
        guard let model = currentModelEntity else { return }
        let newScale = model.scale * scale
        
        // Ensure student doesn't zoom too far in or out
        model.scale = simd_clamp(newScale, [plant.minZoom], [plant.maxZoom])
    }
    
    func highlightPart(named partName: String) {
        guard let modelEntity = currentModelEntity else {
            print("Model not loaded, cannot highlight part")
            return
        }
        
        if let part = findEntity(named: partName, in: modelEntity) {
            var opacity = part.components[OpacityComponent.self] ?? OpacityComponent(opacity: 1.0)
            opacity.opacity = 1.0
            part.components[OpacityComponent.self] = opacity
            print("[AR] Highlighted part: \(partName)")
        } else {
            print("[AR] Part not found in model: \(partName)")
        }
    }
    
    func unhighlightPart(named partName: String) {
        guard let modelEntity = currentModelEntity else { return }
        
        if let part = findEntity(named: partName, in: modelEntity) {
            var opacity = part.components[OpacityComponent.self] ?? OpacityComponent(opacity: 1.0)
            opacity.opacity = 0.7
            part.components[OpacityComponent.self] = opacity
        }
    }
    
    private func findEntity(named name: String, in parent: Entity) -> Entity? {
        if parent.name == name {
            return parent
        }
        
        for child in parent.children {
            if let found = findEntity(named: name, in: child) {
                return found
            }
        }
        
        return nil
    }
    
    // MARK: - Session Management
    
    func startTimeTracking() {
        startTime = Date()
        timeSpentTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            // Timer is running, tracking engagement
        }
    }
    
    func stopTimeTracking() -> Int {
        timeSpentTimer?.invalidate()
        timeSpentTimer = nil
        
        let timeSpent = Int(Date().timeIntervalSince(startTime))
        return max(0, timeSpent)
    }
    
    func removePlant() {
        if let anchor = currentAnchor {
            arView?.scene.removeAnchor(anchor)
        }
        
        stopTimeTracking()
        currentModelEntity = nil
        currentPivotEntity = nil
        currentAnchor = nil
        modelLoaded = false
    }
    
    func pauseARSession() {
        arSession.pause()
    }
    
    // MARK: - AR Session Delegate
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        self.trackingState = frame.camera.trackingState
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let imageAnchor = anchor as? ARImageAnchor {
                print("[AR] Detected reference image: \(imageAnchor.referenceImage.name ?? "Unknown")")
            }
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("[AR] Session error: \(error.localizedDescription)")
        self.error = error.localizedDescription
    }
}

// MARK: - SwiftUI Bridge

struct OptimizedARViewContainer: UIViewRepresentable {
    @ObservedObject var arManager: OptimizedARManager
    let plant: Plant
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arManager.arView = arView
        arManager.setupAR(for: plant)
        
        // Setup Gestures
        let rotation = UIRotationGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleRotation(_:))
        )
        let pinch = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        
        arView.addGestureRecognizer(rotation)
        arView.addGestureRecognizer(pinch)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(arManager: arManager, plant: plant)
    }
    
    class Coordinator: NSObject {
        let arManager: OptimizedARManager
        let plant: Plant
        
        init(arManager: OptimizedARManager, plant: Plant) {
            self.arManager = arManager
            self.plant = plant
        }
        
        @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
            if gesture.state == .changed {
                arManager.applyRotation(Float(gesture.rotation))
                gesture.rotation = 0
            }
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            if gesture.state == .changed {
                arManager.applyZoom(Float(gesture.scale), plant: plant)
                gesture.scale = 1.0
            }
        }
    }
}
