/*
 Core 网络分层（主流 Feature + Clean 简化版）

 Network/        传输：HTTP、加解密原语、URL 拼接、响应解密协议
 Tokens/         启动壳：选线 → splash → JWT / CDN（无 UI）
   Configuration  域名列表
   Client         无状态 API 调用（TokensClient）
   Session        @Observable 内存状态（TokensSession）
   Models         Codable 模型
   Crypto         请求头、响应解密、CDN 解析
 One/            业务 ONE：选线 → 加密 POST → 点播等接口
   同上 Client / Session / Models / API / Configuration / Crypto

 调用链：Feature Session → OneClient / TokensClient → HTTPClient

 Features 不直接写 URL、不加解密细节。
 */

import Foundation
