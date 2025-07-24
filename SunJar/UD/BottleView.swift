//
//  BottleView.swift
//  SunJar
//
//  Created by Shuhari on 7/19/25.
//

import AVFoundation
import CoreHaptics
import CoreMotion
import RiveRuntime
import UIKit

enum SphereType: CaseIterable {
    case perfectDay, niceDay, goodDay
    
    var imageName: String {
        switch self {
        case .perfectDay: "perfect_day"
        case .niceDay: "nice_day"
        case .goodDay: "good_day"
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

class BottleView: UIView {
    private var animator: UIDynamicAnimator!
    
    private var gravityBehavior: UIGravityBehavior!
    private var collisionBehavior: UICollisionBehavior!
    private var itemBehavior: UIDynamicItemBehavior!
    
    private var spheres: [RiveViewModel] = []
    
    private var motionManager: CMMotionManager!
    private var hapticEngine: CHHapticEngine!
    private var collisionPlayer: CHHapticPatternPlayer?
    private var lastHapticTime: TimeInterval = 0
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .clear
        
        setupPhysics()
        createSpheres()
        
        setupHapticEngine()
        setupMotionManager()
    }
    
    private func setupPhysics() {
        animator = UIDynamicAnimator(referenceView: self)
        
        // 初始化行为
        gravityBehavior = UIGravityBehavior()
        collisionBehavior = UICollisionBehavior()
        
        let boundaryPath = createRoundedRectPath(size: bounds.size, cornerRadius: 85)
        collisionBehavior.addBoundary(withIdentifier: "bottleBoundary" as NSCopying, for: boundaryPath)
        collisionBehavior.collisionDelegate = self
        
        itemBehavior = UIDynamicItemBehavior()
        itemBehavior.elasticity = 0.6
        itemBehavior.friction = 0.3
        itemBehavior.density = 1.2
        itemBehavior.resistance = 0.4
        itemBehavior.angularResistance = 0.8
        
        animator.addBehavior(gravityBehavior)
        animator.addBehavior(collisionBehavior)
        animator.addBehavior(itemBehavior)
    }
    
    private func createRoundedRectPath(size: CGSize, cornerRadius: CGFloat) -> UIBezierPath {
        let inset: CGFloat = 4
        let rect = CGRect(
            x: inset,
            y: inset,
            width: size.width - inset * 2,
            height: size.height - inset * 2
        )
        return UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
    }
    
    

    private func createSpheres() {
        let sphereRadius: CGFloat = 20.0
        let sphereTypes = generateShuffledTypes()
        let positions = CirclePackingAlgorithm.packCircles(
            count: sphereTypes.count,
            containerSize: bounds.size,
            cornerRadius: 85,
            circleRadius: sphereRadius
        )
        
        for (index, type) in sphereTypes.enumerated() {
            guard index < positions.count else { continue }
            
            do {
                // 1. 从缓存中同步获取 RiveFile
                let riveFile = try RiveFileCache.shared.file(for: type)
                
                // 2. 为每个球体创建独立的 ViewModel (核心逻辑不变)
                let riveModel = RiveModel(riveFile: riveFile)
                let sphereViewModel = RiveViewModel(riveModel)
                spheres.append(sphereViewModel) // 可选：保存引用
                
                // 3. 从独立的 ViewModel 创建 View
                let sphereView = sphereViewModel.createRiveView()
                sphereView.frame = CGRect(x: 0, y: 0, width: sphereRadius * 2, height: sphereRadius * 2)
                sphereView.center = positions[index]
                sphereView.layer.cornerRadius = sphereRadius
                
                addSubview(sphereView)
//                spheres.append(sphereView)
                
                // ... 物理行为代码保持不变
                gravityBehavior.addItem(sphereView)
                collisionBehavior.addItem(sphereView)
                itemBehavior.addItem(sphereView)
                
                let initialVelocity = CGPoint(x: CGFloat.random(in: -25...25), y: CGFloat.random(in: -15...5))
                itemBehavior.addLinearVelocity(initialVelocity, for: sphereView)
                
            } catch {
                // 如果文件加载失败，打印错误并跳过这个球体
                print("Error loading rive file for type \(type.imageName): \(error)")
            }
        }
    }
    
    private func generateShuffledTypes() -> [SphereType] {
        var types: [SphereType] = []
        for type in SphereType.allCases {
            types.append(contentsOf: Array(repeating: type, count: type.count))
        }
        return types.shuffled()
    }
}

extension BottleView: UICollisionBehaviorDelegate {
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item1: any UIDynamicItem, with item2: any UIDynamicItem, at p: CGPoint) {
        let currentTime = CACurrentMediaTime()
        guard currentTime - lastHapticTime > 0.1 else { return }
        lastHapticTime = currentTime

        guard let view1 = item1 as? UIView, let view2 = item2 as? UIView else { return }

        // 球与球碰撞
        let v1 = itemBehavior.linearVelocity(for: view1)
        let v2 = itemBehavior.linearVelocity(for: view2)
                
        let relativeVelocity = sqrt(pow(v1.x - v2.x, 2) + pow(v1.y - v2.y, 2))
        let normalizedIntensity = min(max(Float(relativeVelocity) / 400.0, 0.0), 1.0)
        playCollisionHaptic(intensity: normalizedIntensity)
    }
    
    func collisionBehavior(_ behavior: UICollisionBehavior, beganContactFor item: UIDynamicItem, withBoundaryIdentifier identifier: NSCopying?, at p: CGPoint) {
        guard let view = item as? UIView else { return }
            
        // 球与边界碰撞
        let velocity = itemBehavior.linearVelocity(for: view)
        let speed = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
            
        let normalizedSpeed = min(max(Float(speed) / 500.0, 0.0), 1.0)
        playCollisionHaptic(intensity: normalizedSpeed)
    }
}

// MARK: - motion

extension BottleView {
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
        let sensitivity = 3.5 // 调整敏感度
        
        let gravityX = CGFloat(gravity.x * sensitivity)
        let gravityY = CGFloat(gravity.y * -sensitivity)
        
        // 更新物理世界重力
        gravityBehavior.gravityDirection = CGVector(dx: gravityX, dy: gravityY)
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

extension BottleView {
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("设备不支持 Core Haptics")
            return
        }
        
        createHapticEngine()
        initializeCollisionHaptics()
        setupAppLifecycleObservers()
    }
    
    private func initializeCollisionHaptics() {
        guard let engine = hapticEngine else { return }
        guard let patternURL = Bundle.main.url(forResource: "CollisionLarge", withExtension: "ahap") else { return }
        
        do {
            let pattern = try CHHapticPattern(contentsOf: patternURL)
            collisionPlayer = try engine.makePlayer(with: pattern)
        } catch {
            print("初始化碰撞反馈失败: \(error)")
        }
    }
    
    private func createHapticEngine() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient)
            try AVAudioSession.sharedInstance().setActive(true)
            hapticEngine = try CHHapticEngine(audioSession: .sharedInstance())
            try hapticEngine?.start()
            
            hapticEngine?.resetHandler = { [weak self] in
                print("Haptic Engine Reset")
                try? self?.hapticEngine?.start()
                self?.initializeCollisionHaptics()
            }
            
            hapticEngine?.stoppedHandler = { reason in
                print("Haptic Engine Stopped: \(reason)")
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
            try? self?.hapticEngine?.start()
        }
            
        // 应用失去焦点
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.hapticEngine?.stop()
        }
    }
    
    func playCollisionHaptic(intensity: Float) {
        guard let player = collisionPlayer, intensity > 0.1 else { return }
                
        do {
            // 确保引擎已启动
            try hapticEngine?.start()
                    
            // 动态调整参数
            let intensityValue = linearInterpolation(alpha: intensity, min: 0.3, max: 1.0)
            let intensityParameter = CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
                                                              value: intensityValue,
                                                              relativeTime: 0)
                    
            let volumeValue = linearInterpolation(alpha: intensity, min: 0.1, max: 0.5)
            let volumeParameter = CHHapticDynamicParameter(parameterID: .audioVolumeControl,
                                                           value: volumeValue,
                                                           relativeTime: 0)
                    
            // 发送参数并播放
            try player.sendParameters([intensityParameter, volumeParameter], atTime: 0)
            try player.start(atTime: 0)
                    
        } catch {
            print("Haptic Playback Failed: \(error)")
        }
    }
    
    private func linearInterpolation(alpha: Float, min: Float, max: Float) -> Float {
        return min + alpha * (max - min)
    }
}

extension RiveView {
    override open var collisionBoundsType: UIDynamicItemCollisionBoundsType {
        .ellipse
    }
}
