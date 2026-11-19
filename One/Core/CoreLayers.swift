/*
 项目分层（主流 iOS：Feature + 薄 Core）

 App/            入口（OneApp、ContentView）
 Features/       按业务分文件夹（Home / Discover / Article …）
   Views         界面
   Session       @Observable 状态与请求编排
   Models        仅本 Feature 用的模型
 Shared/         多 Feature 共用（UI、导航、图片、评论模型…）
 Core/
   Network/      HTTP 传输
   Tokens/       启动壳：选线、JWT、CDN
   One/
     Client/     OneClient（传输）+ 业务 API 文件（ArticleAPI / UserAPI …）
     Models/     接口模型（一文一类型，便于查找）
     Crypto/     签名与加解密

 调用链（记住这一条即可）：
   View → Feature Session → OneClient / TokensClient → HTTPClient

 不要：在 View 里拼 URL、写加解密、直接依赖其它 Feature 的私有模型。
 */

import Foundation
