//
//  ViewController.swift
//  SunJar
//
//  Created by Shuhari on 7/14/25.
//

import SnapKit
import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let bottleView = BottleView()
        view.addSubview(bottleView)
        bottleView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 290, height: 345))
        }
    }
}

