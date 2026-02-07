import Foundation
import ServiceManagement
import SwiftUI
import Combine

// 开机启动管理器
class LaunchAtLoginManager: ObservableObject {
    // 开机启动是否启用的状态
    @Published var isEnabled: Bool = false
    
    init() {
        // 检查当前系统的开机启动状态
        checkStatus()
    }
    
    // 检查当前的开机启动状态
    func checkStatus() {
        if #available(macOS 13.0, *) {
            self.isEnabled = SMAppService.mainApp.status == .enabled
        } else {
            self.isEnabled = false
        }
    }
    
    func toggle() {
        if #available(macOS 13.0, *) {
            do {
                if isEnabled {
                    // 禁用开机启动
                    try SMAppService.mainApp.unregister()
                    self.isEnabled = false
                } else {
                    // 启用开机启动
                    try SMAppService.mainApp.register()
                    self.isEnabled = true
                }
            } catch {
                print("切换开机启动失败: \(error)")
                checkStatus() // 如果失败，回滚状态
            }
        }
    }
}
