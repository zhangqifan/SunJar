//
//  BottleScene.swift
//  SunJar
//
//  Created by Shuhari on 7/18/25.
//

import UIKit
import SpriteKit
import CoreMotion
import CoreHaptics

class BottleScene: SKScene {
    
    enum PhysicsCategory {
        static let sphere: UInt32 = 1       // 0001
        static let boundary: UInt32 = 2     // 0010
    }
    
    private var motionManager: CMMotionManager!
    private var hapticEngine: CHHapticEngine!
    private var lastHapticTime: TimeInterval = 0

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        setupPhysicsWorld()
        setupHapticEngine()
        setupMotionManager()
        createBoundary()
        createSpheres()
    }
    
    private func setupPhysicsWorld() {
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.speed = 1
    }
}

extension BottleScene: SKPhysicsContactDelegate {
    
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        // 球与边界碰撞
        if collision == PhysicsCategory.sphere | PhysicsCategory.boundary {
            let ballBody = contact.bodyA.categoryBitMask == PhysicsCategory.sphere ?
            contact.bodyA : contact.bodyB
            let velocity = ballBody.velocity
            let speed = sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
            
            let normalizedSpeed = min(max(Float(speed) / 500.0, 0.0), 1.0)
            playCollisionHaptic(intensity: normalizedSpeed)
        }
        
        // 球与球碰撞
        else if collision == PhysicsCategory.sphere | PhysicsCategory.sphere {
            let currentTime = CACurrentMediaTime()
            guard currentTime - lastHapticTime > 0.1 else { return }
            lastHapticTime = currentTime
            
            let bodyA = contact.bodyA
            let bodyB = contact.bodyB
            let relativeVelocity = sqrt(
                pow(bodyA.velocity.dx - bodyB.velocity.dx, 2) +
                pow(bodyA.velocity.dy - bodyB.velocity.dy, 2)
            )
            
            let normalizedIntensity = min(max(Float(relativeVelocity) / 400.0, 0.0), 1.0)
            playCollisionHaptic(intensity: normalizedIntensity)
        }
    }
}


// MARK: - spheres

extension BottleScene {
    
    // MARK: - Sphere Types
    
    enum SphereType: CaseIterable {
        case perfectDay, niceDay, goodDay
        
        var imageName: String {
            switch self {
            case .perfectDay: "perfect"
            case .niceDay: "nice"
            case .goodDay: "good"
            }
        }
        
        var count: Int {
            switch self {
            case .perfectDay: 7
            case .niceDay: 5
            case .goodDay: 5
            }
        }
    }
    
    private func createSpheres() {
        let sphereRadius: CGFloat = 20.0
        let sphereTypes = generateShuffledTypes()
        
        // 使用圆形填充算法获取位置
        let positions = CirclePackingAlgorithm.packCircles(
            count: sphereTypes.count,
            containerSize: size,
            cornerRadius: 85,
            circleRadius: sphereRadius
        )
        
        // 创建小球
        for (index, type) in sphereTypes.enumerated() {
            if index < positions.count {
                let sphere = createSphere(type: type, radius: sphereRadius, at: positions[index])
                addChild(sphere)
            }
        }
    }
    
    private func createSphere(type: SphereType, radius: CGFloat, at position: CGPoint) -> SKSpriteNode {
        let sphere = SKSpriteNode(imageNamed: type.imageName, normalMapped: true)
        sphere.name = type.imageName
        sphere.size = CGSize(width: radius * 2, height: radius * 2)
        sphere.position = position
        
        sphere.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        sphere.physicsBody?.categoryBitMask = PhysicsCategory.sphere
        sphere.physicsBody?.collisionBitMask = PhysicsCategory.boundary | PhysicsCategory.sphere
        sphere.physicsBody?.contactTestBitMask = PhysicsCategory.boundary | PhysicsCategory.sphere
        sphere.physicsBody?.restitution = 0.4
        sphere.physicsBody?.friction = 0.8
        sphere.physicsBody?.mass = 1.2
        sphere.physicsBody?.linearDamping = 0.4
        sphere.physicsBody?.angularDamping = 0.8
        
        sphere.physicsBody?.velocity = CGVector(
            dx: CGFloat.random(in: -25...25),
            dy: CGFloat.random(in: -15...5)
        )
        
        return sphere
    }
    
    private func generateShuffledTypes() -> [SphereType] {
        var types: [SphereType] = []
        for type in SphereType.allCases {
            types.append(contentsOf: Array(repeating: type, count: type.count))
        }
        return types.shuffled()
    }
}

// MARK: - boundary

extension BottleScene {
    
    private func createBoundary() {
        childNode(withName: "Boundary")?.removeFromParent()
        
        let boundaryNode = SKNode()
        boundaryNode.name = "Boundary"
        
        let boundaryPath = createRoundedRectPath(size: size, cornerRadius: 85)
        
        boundaryNode.physicsBody = SKPhysicsBody(edgeLoopFrom: boundaryPath)
        boundaryNode.physicsBody?.categoryBitMask = PhysicsCategory.boundary
        boundaryNode.physicsBody?.collisionBitMask = PhysicsCategory.sphere
        boundaryNode.physicsBody?.contactTestBitMask = PhysicsCategory.sphere
        boundaryNode.physicsBody?.friction = 0.3
        boundaryNode.physicsBody?.restitution = 0.6
        
#if DEBUG
        let shapeNode = SKShapeNode(path: boundaryPath)
        shapeNode.strokeColor = .red
        shapeNode.lineWidth = 2
        shapeNode.fillColor = .clear
        boundaryNode.addChild(shapeNode)
#endif
        
        addChild(boundaryNode)
    }
    
    private func createRoundedRectPath(size: CGSize, cornerRadius: CGFloat) -> CGPath {
        let inset: CGFloat = 4
        let rect = CGRect(
            x: inset,
            y: inset,
            width: size.width - inset * 2,
            height: size.height - inset * 2
        )
        
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        return path.cgPath
    }
}

// MARK: - motion

extension BottleScene {
    func setupMotionManager() {
        motionManager = CMMotionManager()
        
        guard motionManager.isDeviceMotionAvailable else {
            print("设备不支持运动检测")
            return
        }
        
        // 设置更新频率 (60Hz)
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        
        startMotionUpdates()
    }
    
    private func startMotionUpdates() {
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self,
                  let motion = motion,
                  error == nil
            else {
                print("Motion update error: \(error?.localizedDescription ?? "Unknown")")
                return
            }
            
            self.handleMotionUpdate(motion)
        }
    }
    
    private func handleMotionUpdate(_ motion: CMDeviceMotion) {
        let gravity = motion.gravity
        
        // 映射设备方向到物理世界
        // 设备竖直向上时，gravity.x ≈ 0, gravity.y ≈ -1
        let sensitivity = 15.0 // 调整敏感度
        
        let gravityX = CGFloat(gravity.x * sensitivity)
        let gravityY = CGFloat(gravity.y * sensitivity)
        
        // 更新物理世界重力
        physicsWorld.gravity = CGVector(dx: gravityX, dy: gravityY)
    }
    
    func stopMotionUpdates() {
        motionManager?.stopDeviceMotionUpdates()
    }
    
    func pauseMotionUpdates() {
        motionManager?.stopDeviceMotionUpdates()
    }
    
    func resumeMotionUpdates() {
        startMotionUpdates()
    }
}

// MARK: - Core Haptics

extension BottleScene {
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("设备不支持 Core Haptics")
            return
        }
        
        createHapticEngine()
        setupAppLifecycleObservers()
    }
    
    private func createHapticEngine() {
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            
            hapticEngine?.resetHandler = { [weak self] in
                print("Haptic Engine Reset")
                try? self?.hapticEngine?.start()
            }
            
            hapticEngine?.stoppedHandler = { [weak self] reason in
                print("Haptic Engine Stopped: \(reason)")
                // 重新启动引擎
                DispatchQueue.main.async {
                    try? self?.hapticEngine?.start()
                }
            }
            
        } catch {
            print("Haptic Engine setup failed: \(error)")
        }
    }
    
    private func setupAppLifecycleObservers() {
        // 应用变为活跃
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.restartHapticEngine()
        }
        
        // 应用失去焦点
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.stopHapticEngine()
        }
    }
    
    private func restartHapticEngine() {
        print("重启 Haptic Engine")
        
        // 停止旧引擎
        hapticEngine?.stop()
        hapticEngine = nil
        
        // 创建新引擎
        createHapticEngine()
    }
    
    private func stopHapticEngine() {
        print("停止 Haptic Engine")
        hapticEngine?.stop()
    }
    
    func playCollisionHaptic(intensity: Float) {
        guard let hapticEngine = hapticEngine,
              intensity > 0.1 else { return }
        
        // 确保引擎正在运行
        guard hapticEngine.currentTime > 0 else {
            print("Haptic Engine 未运行，尝试重启")
            restartHapticEngine()
            return
        }
        
        do {
            let pattern = createHapticPattern(intensity: intensity)
            let player = try hapticEngine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Haptic playback failed: \(error)")
            // 重试一次
            restartHapticEngine()
        }
    }
    
    private func createHapticPattern(intensity: Float) -> CHHapticPattern {
        let adjustedIntensity = min(max(intensity, 0.1), 1.0)
        
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: adjustedIntensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ],
            relativeTime: 0
        )
        
        return try! CHHapticPattern(events: [event], parameters: [])
    }
    
    func cleanupHaptics() {
        NotificationCenter.default.removeObserver(self)
        hapticEngine?.stop()
        hapticEngine = nil
    }
}

