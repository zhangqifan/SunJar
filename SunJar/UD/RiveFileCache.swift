//
//  RiveFileCache.swift
//  SunJar
//
//  Created by Shuhari on 7/21/25.
//


import RiveRuntime
import Foundation

// 使用 DispatchQueue 实现线程安全的单例缓存
final class RiveFileCache {
    static let shared = RiveFileCache()
    
    // 私有缓存字典
    private var cache: [SphereType: RiveFile] = [:]
    
    // 创建一个串行队列，确保所有对 cache 的访问都是顺序执行的
    private let accessQueue = DispatchQueue(label: "com.shuhari.rivefile.cache.queue")

    private init() {} // 强制使用 shared 单例

    func file(for type: SphereType) throws -> RiveFile {
        return try accessQueue.sync {
            if let cachedFile = cache[type] {
                return cachedFile
            }
            
            let newFile = try RiveFile(name: type.imageName)
            cache[type] = newFile
            return newFile
        }
    }

}
