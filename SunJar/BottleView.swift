//
//  BottleView.swift
//  SunJar
//
//  Created by Shuhari on 7/15/25.
//

import SpriteKit
import UIKit
import SnapKit

/// BottleView 的组成：
/// 1. `SKView` 负责呈现 `SKScene` 内容
/// 2. `SKScene` 负责所有物理模拟
/// 3. 上层罐盖（w240:h52）和罐身（w290:h345）的贴图

class BottleView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(presentationView)
        addSubview(bottle)
        addSubview(cap)
        
        presentationView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        bottle.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        cap.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 240, height: 52))
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(-31)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if presentationView.scene == nil {
            setupScene()
        }
    }
    
    private func setupScene() {
        bottleScene.scaleMode = .aspectFill
        bottleScene.size = presentationView.bounds.size
        
#if DEBUG
        presentationView.showsFPS = true
        presentationView.showsNodeCount = true
        presentationView.showsDrawCount = true
        presentationView.showsPhysics = true
        presentationView.showsFields = true
#endif
        
        presentationView.presentScene(bottleScene)
    }
    
    // MARK: - elements
    
    lazy var cap: UIImageView = {
        let cap = UIImageView(image: .cap)
        cap.contentMode = .scaleAspectFit
        return cap
    }()
    
    lazy var bottle: UIImageView = {
        let bottle = UIImageView(image: .bottle)
        bottle.contentMode = .scaleAspectFit
        return bottle
    }()
    
    lazy var presentationView: SKView = {
        let view = SKView()
        view.isOpaque = false
        return view
    }()
    
    lazy var bottleScene: BottleScene = {
        let scene = BottleScene()
        return scene
    }()
}

