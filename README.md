# SunJar 🫙

一个充满创意的 iOS 应用，通过物理模拟的方式可视化你的日常心情和状态。

## 📖 项目简介

SunJar 是一个基于物理引擎的交互式应用，模拟一个装满彩色小球的瓶子。每个小球代表不同类型的日子：
- 🌟 **Perfect Day** - 完美的一天
- ✨ **Nice Day** - 不错的一天  
- 🌈 **Good Day** - 好的一天

通过倾斜设备，你可以看到小球在瓶子中自然滚动，感受物理世界的真实反馈。

## ✨ 核心功能

### 🎮 物理模拟
- 基于 **SpriteKit** 的真实物理引擎
- 支持重力、碰撞、摩擦等物理效果
- 小球之间和与边界的碰撞检测

### 📱 运动感应
- 利用 **Core Motion** 检测设备倾斜
- 实时调整瓶内重力方向
- 60Hz 高频率更新，流畅响应

### 🎯 触觉反馈
- 集成 **Core Haptics** 引擎
- 碰撞强度对应震动强度
- 支持不同类型的触觉效果

### 🎨 精美界面
- 自定义瓶子和盖子贴图
- 圆角矩形边界设计
- 透明背景，视觉层次丰富

### 🧮 智能算法
- **圆形填充算法** 优化小球初始位置
- 防重叠的网格备用放置策略
- 支持任意数量小球的合理分布

## 🛠 技术栈

- **Swift** - 主要开发语言
- **UIKit** - 用户界面框架
- **SpriteKit** - 2D 游戏和物理引擎
- **Core Motion** - 设备运动检测
- **Core Haptics** - 触觉反馈系统
- **SnapKit** - 自动布局库

## 📁 项目结构

```
SunJar/
├── AppDelegate.swift              # 应用委托
├── SceneDelegate.swift            # 场景委托
├── ViewController.swift           # 主视图控制器
├── BottleView.swift              # 瓶子容器视图
├── BottleScene.swift             # SpriteKit 物理场景
├── CirclePackingAlgorithm.swift  # 圆形填充算法
├── Assets.xcassets/              # 图像资源
│   ├── bottle.imageset/          # 瓶子贴图
│   ├── cap.imageset/             # 盖子贴图
│   ├── perfect.imageset/         # 完美日子小球
│   ├── nice.imageset/            # 不错日子小球
│   └── good.imageset/            # 好日子小球
└── Base.lproj/
    └── LaunchScreen.storyboard   # 启动屏幕
```

## 🚀 快速开始

### 环境要求

- iOS 13.0+
- Xcode 12.0+
- Swift 5.0+

### 安装步骤

1. **克隆项目**
   ```bash
   git clone https://github.com/zhangqifan/SunJar.git
   cd SunJar
   ```

2. **打开项目**
   ```bash
   open SunJar.xcodeproj
   ```

3. **安装依赖**
   - 项目使用 Swift Package Manager
   - Xcode 会自动解析和下载 `SnapKit` 依赖

4. **运行应用**
   - 选择目标设备或模拟器
   - 按 `Cmd + R` 运行

> **注意**: 为了体验完整的运动感应和触觉反馈功能，建议在真实设备上运行。

## 🎯 使用方法

1. **启动应用** - 应用加载后会显示装满小球的瓶子
2. **倾斜设备** - 向不同方向倾斜 iPhone/iPad，观察小球滚动
3. **感受反馈** - 小球碰撞时会产生相应的触觉震动
4. **享受物理** - 体验真实的重力、惯性和碰撞效果

## 🔧 自定义配置

### 调整小球数量
在 `BottleScene.swift` 中修改 `SphereType` 枚举：

```swift
enum SphereType: CaseIterable {
    case perfectDay, niceDay, goodDay
    
    var count: Int {
        switch self {
        case .perfectDay: 7    // 修改完美日子数量
        case .niceDay: 5       // 修改不错日子数量  
        case .goodDay: 5       // 修改好日子数量
        }
    }
}
```

### 调整物理参数
在 `BottleScene.swift` 中的 `createSphere` 方法中修改：

```swift
sphere.physicsBody?.restitution = 0.4    // 弹性
sphere.physicsBody?.friction = 0.8       // 摩擦力
sphere.physicsBody?.mass = 1.2           // 质量
sphere.physicsBody?.linearDamping = 0.4  // 线性阻尼
```

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 📞 联系方式

- 作者: shuhari
- 项目链接: [https://github.com/zhangqifan/SunJar](https://github.com/zhangqifan/SunJar)

## 🙏 致谢

- 感谢 [SnapKit](https://github.com/SnapKit/SnapKit) 提供优雅的自动布局解决方案
- 感谢 Apple 提供强大的 SpriteKit 和 Core Motion 框架

---

**🌟 如果这个项目对你有帮助，请给它一个 Star！** 