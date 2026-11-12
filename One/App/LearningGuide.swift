/*
 =============================================================================
  One 项目学习导读（随代码阅读，无需编译运行本文件）
 =============================================================================

 【SwiftUI 是什么】
 用 Swift 声明「界面长什么样」，系统负责绘制与更新。每个屏幕是一个 struct，遵守 View 协议。

 【本项目分层】
 App/          → 程序入口、根路由（先启动页 or 主界面）
 Features/     → 各 Tab 的界面 + 该功能的 Session（状态）
 Core/         → 网络、加解密、API，不放 UI
 Shared/       → 多个功能共用的 UI（如底部 Tab 容器）

 【数据怎么流动】
 1. EntryView 启动 → TokensSession 拉 token，OneSession 选 API 线路
 2. 进入 MainTabView → 点播 Tab 用 TabSession 拉分类与列表
 3. View 用 @Bindable / @State 订阅 Session，数据变了界面自动刷新（Observation）

 【异步 async/await】
 网络请求会等待，不阻塞主线程。在 View 里写 Task { await xxx() }，或在 .task { } 里直接 await。

 【建议阅读顺序】
 MyApp → ContentView → EntryView → TokensSession / OneSession
 → MainTabView → Tab / TabSession → HTTPClient → OneClient

 =============================================================================
 */

import Foundation
