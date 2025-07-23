//
//  configure.swift
//  ocrl
//  Created by JoyTim on 2025/7/23
//  Copyright © 2025 . All rights reserved.
//

import Vapor

public func configure(_ app: Application) throws {
    // 配置文件上传限制 (10MB)
    app.routes.defaultMaxBodySize = "10mb"

    // 健康检查
    app.get("health") { _ in
        ["status": "healthy", "timestamp": Date().ISO8601Format()]
    }

    // OCR API 路由
    try app.register(collection: OCRController())
}
