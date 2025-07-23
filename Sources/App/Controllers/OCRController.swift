//
//  OCRController.swift
//  ocrl
//  Created by JoyTim on 2025/7/23
//  Copyright © 2025 . All rights reserved.
//
    
import MultipartKit
import Vapor

struct OCRMultipartForm: Content {
    var image: Data
    var language: String?
}

struct OCRInfoResponse: Content {
    let service: String
    let version: String
    let framework: String
    let supported_formats: [String]
    let max_file_size: String
    let supported_languages: [String]
    let endpoints: [String: String]
}

struct OCRController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let ocr = routes.grouped("api", "v1", "ocr")
        ocr.post(use: performOCR)
        ocr.get("info", use: getInfo)
    }
    
    func performOCR(req: Request) async throws -> OCRResponse {
        req.logger.info("performOCR called")
        // 检查 Content-Type
        guard let contentType = req.headers.contentType else {
            return OCRResponse.failure(error: "Missing Content-Type header")
        }
        
        let imageData: Data
        var language: String?
        var confidence: Float? = nil
        
        // 处理不同的上传方式
        if contentType.type == "multipart" {
            // multipart/form-data 上传
            let form = try req.content.decode(OCRMultipartForm.self)
            imageData = form.image
            language = form.language
        
        } else if contentType.type == "application" && contentType.subType == "octet-stream" {
            // 二进制数据直接上传
            imageData = Data(buffer: req.body.data ?? ByteBuffer())
            language = req.query["language"]
        
        } else if contentType.type == "application" && contentType.subType == "json" {
            // application/json 方式
            let ocrRequest = try req.content.decode(OCRRequest.self)
            language = ocrRequest.language
            confidence = ocrRequest.confidence
            // 这里假设图片以 base64 字符串方式传递
            guard let base64Image = ocrRequest.image else {
                req.logger.error("image 字段缺失或为 nil")
                return OCRResponse.failure(error: "Missing image data in JSON")
            }
            // 兼容 data:image/png;base64, 前缀
            let cleanedBase64Image: String
            if let range = base64Image.range(of: ",") {
                cleanedBase64Image = String(base64Image[range.upperBound...])
            } else {
                cleanedBase64Image = base64Image
            }
            guard let data = Data(base64Encoded: cleanedBase64Image) else {
                req.logger.error("Base64 decode failed. cleanedBase64Image prefix: \(cleanedBase64Image.prefix(100))")
                return OCRResponse.failure(error: "Invalid base64 image data in JSON")
            }
            imageData = data
        
        } else {
            return OCRResponse.failure(error: "Unsupported Content-Type. Use multipart/form-data, application/octet-stream or application/json")
        }
        
        // 验证图片数据
        if imageData.isEmpty {
            return OCRResponse.failure(error: "Empty image data")
        }
        
        if imageData.count > 10 * 1024 * 1024 { // 10MB
            return OCRResponse.failure(error: "Image too large (max 10MB)")
        }
        
        // 执行 OCR
        do {
            let result = try await VisionOCRService.shared.recognizeText(
                from: imageData,
                language: language,
                confidence: confidence
            )
            return OCRResponse.success(data: result)
        } catch VisionOCRService.OCRError.invalidImageData {
            return OCRResponse.failure(error: "Invalid image format")
        } catch VisionOCRService.OCRError.noTextFound {
            return OCRResponse.failure(error: "No text found in image")
        } catch {
            req.logger.error("OCR processing failed: \(error)")
            return OCRResponse.failure(error: "OCR processing failed")
        }
    }
    
    func getInfo(req: Request) -> OCRInfoResponse {
        return OCRInfoResponse(
            service: "OCR Service",
            version: "1.0.0",
            framework: "Vapor + Vision",
            supported_formats: ["jpg", "jpeg", "png", "tiff", "bmp"],
            max_file_size: "10MB",
            supported_languages: ["zh-CN", "en-US"],
            endpoints: [
                "POST /api/v1/ocr": "Perform OCR on uploaded image",
                "GET /api/v1/ocr/info": "Service information",
                "GET /health": "Health check"
            ]
        )
    }
}
