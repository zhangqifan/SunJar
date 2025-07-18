//
//  CirclePackingAlgorithm.swift
//  SunJar
//
//  Created by Shuhari on 7/18/25.
//

import Foundation
import UIKit

struct CirclePackingAlgorithm {
    static func packCircles(count: Int,
                            containerSize: CGSize,
                            cornerRadius: CGFloat,
                            circleRadius: CGFloat) -> [CGPoint] {
        
        var positions: [CGPoint] = []
        let maxAttempts = 1000
        
        // 计算有效区域（用于随机生成候选位置）
        let inset: CGFloat = 4 // 与边界保持一致
        let margin = circleRadius + 3
        let safeRect = CGRect(
            x: inset + margin,
            y: inset + margin,
            width: containerSize.width - 2 * (inset + margin),
            height: containerSize.height - 2 * (inset + margin)
        )
        
        for _ in 0..<count {
            var placed = false
            var attempts = 0
            
            while !placed && attempts < maxAttempts {
                // 在安全区域内随机生成候选位置
                let x = CGFloat.random(in: safeRect.minX...safeRect.maxX)
                let y = CGFloat.random(in: safeRect.minY...safeRect.maxY)
                let candidate = CGPoint(x: x, y: y)
                
                // 检查是否在圆角矩形内（复用你现有的检查逻辑）
                if isValidPosition(candidate, containerSize: containerSize, cornerRadius: cornerRadius, margin: margin) {
                    
                    // 检查是否与已有圆形重叠
                    var canPlace = true
                    for existingPos in positions {
                        let distance = sqrt(pow(candidate.x - existingPos.x, 2) + pow(candidate.y - existingPos.y, 2))
                        if distance < circleRadius * 2.2 { // 稍微增加间距避免过于紧密
                            canPlace = false
                            break
                        }
                    }
                    
                    if canPlace {
                        positions.append(candidate)
                        placed = true
                    }
                }
                
                attempts += 1
            }
            
            // 如果随机放置失败，尝试网格放置
            if !placed {
                if let gridPosition = findGridPosition(
                    existingPositions: positions,
                    containerSize: containerSize,
                    cornerRadius: cornerRadius,
                    circleRadius: circleRadius
                ) {
                    positions.append(gridPosition)
                }
            }
        }
        
        return positions
    }
    
    // 辅助方法：验证位置是否有效（复用你现有的逻辑）
    private static func isValidPosition(_ position: CGPoint,
                                        containerSize: CGSize,
                                        cornerRadius: CGFloat,
                                        margin: CGFloat) -> Bool {
        let inset: CGFloat = 4
        
        let safeRect = CGRect(
            x: inset + margin,
            y: inset + margin,
            width: containerSize.width - 2 * (inset + margin),
            height: containerSize.height - 2 * (inset + margin)
        )
        
        // 基础边界检查
        guard position.x >= safeRect.minX && position.x <= safeRect.maxX &&
                position.y >= safeRect.minY && position.y <= safeRect.maxY
        else {
            return false
        }
        
        // 圆角检查
        let adjustedCornerRadius = cornerRadius - margin
        
        // 检查四个角
        let corners = [
            CGPoint(x: safeRect.minX + adjustedCornerRadius, y: safeRect.minY + adjustedCornerRadius),
            CGPoint(x: safeRect.maxX - adjustedCornerRadius, y: safeRect.minY + adjustedCornerRadius),
            CGPoint(x: safeRect.minX + adjustedCornerRadius, y: safeRect.maxY - adjustedCornerRadius),
            CGPoint(x: safeRect.maxX - adjustedCornerRadius, y: safeRect.maxY - adjustedCornerRadius)
        ]
        
        for (i, corner) in corners.enumerated() {
            let dx = position.x - corner.x
            let dy = position.y - corner.y
            
            let inCornerRegion: Bool
            switch i {
            case 0: inCornerRegion = dx <= 0 && dy <= 0 // 左下
            case 1: inCornerRegion = dx >= 0 && dy <= 0 // 右下
            case 2: inCornerRegion = dx <= 0 && dy >= 0 // 左上
            case 3: inCornerRegion = dx >= 0 && dy >= 0 // 右上
            default: inCornerRegion = false
            }
            
            if inCornerRegion {
                let distance = sqrt(dx * dx + dy * dy)
                if distance > adjustedCornerRadius {
                    return false
                }
            }
        }
        
        return true
    }
    
    // 备用网格放置方法
    private static func findGridPosition(existingPositions: [CGPoint],
                                         containerSize: CGSize,
                                         cornerRadius: CGFloat,
                                         circleRadius: CGFloat) -> CGPoint? {
        let spacing = circleRadius * 2.2
        let inset: CGFloat = 4
        let margin = circleRadius + 3
        
        let safeRect = CGRect(
            x: inset + margin,
            y: inset + margin,
            width: containerSize.width - 2 * (inset + margin),
            height: containerSize.height - 2 * (inset + margin)
        )
        
        let cols = Int(safeRect.width / spacing)
        let rows = Int(safeRect.height / spacing)
        
        // 从中心开始螺旋搜索
        let centerCol = cols / 2
        let centerRow = rows / 2
        
        for radius in 0..<max(cols, rows) {
            for row in max(0, centerRow - radius)...min(rows - 1, centerRow + radius) {
                for col in max(0, centerCol - radius)...min(cols - 1, centerCol + radius) {
                    // 只检查螺旋边缘
                    if radius == 0 || row == centerRow - radius || row == centerRow + radius ||
                        col == centerCol - radius || col == centerCol + radius {
                        
                        let x = safeRect.minX + CGFloat(col) * spacing
                        let y = safeRect.minY + CGFloat(row) * spacing
                        let candidate = CGPoint(x: x, y: y)
                        
                        if isValidPosition(candidate, containerSize: containerSize, cornerRadius: cornerRadius, margin: margin) {
                            // 检查与现有位置的距离
                            var canPlace = true
                            for existingPos in existingPositions {
                                let distance = sqrt(pow(candidate.x - existingPos.x, 2) + pow(candidate.y - existingPos.y, 2))
                                if distance < circleRadius * 2.2 {
                                    canPlace = false
                                    break
                                }
                            }
                            
                            if canPlace {
                                return candidate
                            }
                        }
                    }
                }
            }
        }
        
        return nil
    }
}

