//
//  OCRModels.swift
//  ocrl
//  Created by JoyTim on 2025/7/23
//  Copyright © 2025 . All rights reserved.
//

import Foundation
import Vapor

struct OCRRequest: Content {
    let image: String?           // 新增
    let language: String?
    let recognitionLevel: String?
    let confidence: Float? // 单一语言置信度
}

struct OCRResponse: Content {
    let status: String
    let data: OCRData?
    let error: String?

    struct OCRData: Content {
        let text: String
        let confidence: Float
        let processingTime: Int // milliseconds
        let boundingBoxes: [BoundingBox]?
    }

    struct BoundingBox: Content {
        let text: String
        let confidence: Float
        let x: Float
        let y: Float
        let width: Float
        let height: Float
    }
}

extension OCRResponse {
    static func success(data: OCRData) -> OCRResponse {
        return OCRResponse(status: "success", data: data, error: nil)
    }

    static func failure(error: String) -> OCRResponse {
        return OCRResponse(status: "error", data: nil, error: error)
    }
}
