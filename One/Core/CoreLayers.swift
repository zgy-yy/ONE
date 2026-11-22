/*
 项目分层（主流 iOS：Feature + 薄 Core）

 App/            入口（OneApp、ContentView）
 Features/       按业务分文件夹（Home / Discover / Article …）
   Detail/Views  界面
   Session       @Observable：拉数、编排、把结果交给 View
 Shared/         多 Feature 共用
   UI/           Row、导航、通用控件
   UI/Reactions/ 喜欢 / 收藏 UI 与移夹流程（ArticleCollectFlow）
   Models/       评论、反应状态（ArticleReactionStore）等
 Core/
   Network/      HTTP 传输
   Tokens/       启动壳：选线、JWT、CDN
   One/
     Client/     OneClient + ArticleAPI / UserAPI …
     Models/     接口模型（一文一文件）
     Crypto/     签名与加解密

 调用链（记住这一条）：
   View → Feature Session → OneClient → HTTPClient

 喜欢 / 收藏：
   列表 ArticleCollectLikeMeta / 详情 ArticleDetailEngagementRow
   → ArticleReactionStore → OneClient.articleLike/Collect
   收藏后移夹：ArticleCollectAction + articleCollectMoveFlow

 不要：在 View 里拼 URL、写加解密、直接依赖其它 Feature 的私有类型。
 */

import Foundation
