/*
 =============================================================================
  One 项目学习导读（随代码阅读，无需编译运行本文件）
 =============================================================================

 【SwiftUI 是什么】
 用 Swift 声明「界面长什么样」，系统负责绘制与更新。每个屏幕是一个 struct，遵守 View 协议。

 【目录规范（Feature + Core）】

 App/                 程序入口、根路由（`OneApp`、`ContentView`）
 Resources/           资源（Asset Catalog 等）

 Shared/              跨功能复用、不放业务状态
   Navigation/        主 Tab 壳（`MainTabView`）

 Core/                无 UI 的基础设施
   Networking/        HTTP、加解密、通用编解码
   One/               ONE 业务 API、线路、列表模型
   Tokens/            壳配置拉取、JWT、CDN 基址

 Features/            按产品功能垂直切分；复杂模块再分子目录
   Entry/             启动/bootstrap
   Home/ Discover/ …  单屏 Tab：`FeatureView.swift`
   OnDemand/          多屏示例：
     Models/          筛选、缓存等值类型（`MonthYear`、`TagsArticles`）
     Session/         `@Observable` 状态（`OnDemandSession`）
     Views/           页面（`OnDemandView`、`OnDemandTagPane`）
     Components/      顶栏、分类条、筛选等组件
     Theme/           模块 UI 样式（`OnDemandUI`）

 【数据怎么流动】
 1. EntryView 启动 → TokensSession 拉 token，OneSession 选 API 线路
 2. 进入 MainTabView → 点播用 OnDemandSession 拉分类与列表
 3. View 用 @Bindable / @State 订阅 Session，数据变了界面自动刷新（Observation）

 【异步 async/await】
 网络请求会等待，不阻塞主线程。在 View 里写 Task { await xxx() }，或在 .task { } 里直接 await。

 【建议阅读顺序】
 OneApp → ContentView → EntryView → TokensSession / OneSession
 → MainTabView → OnDemandView / OnDemandSession → HTTPClient → OneClient

 =============================================================================
 */

import Foundation
