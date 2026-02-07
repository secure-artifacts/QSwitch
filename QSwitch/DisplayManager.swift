import Foundation
import CoreGraphics
import Combine

class DisplayManager: ObservableObject {
    // 所有可用的显示模式列表
    @Published var availableModes: [DisplayMode] = []
    @Published var currentWidth: Int = 0
    
    // 封装单个分辨率配置的所有必要信息
    struct DisplayMode: Hashable, Identifiable {
        let id = UUID()
        let width: Int
        let height: Int
        let pixelWidth: Int
        let mode: CGDisplayMode
        
        // 显示分辨率
        var title: String {
            return "\(width) x \(height)"
        }
    }
    
    // 加载所有可用的显示模式
    func fetchModes() {
        // 获取主显示器的 ID
        let mainDisplay = CGMainDisplayID()
        
        // 读取系统当前正在使用的分辨率，并且选中
        if let currentMode = CGDisplayCopyDisplayMode(mainDisplay) {
            self.currentWidth = currentMode.width
        }
        
        // 获取所有可用显示模式列表
        let options: [String: Any] = [kCGDisplayShowDuplicateLowResolutionModes as String: true]
        
        // 获取所有显示模式
        guard let modes = CGDisplayCopyAllDisplayModes(mainDisplay, options as CFDictionary) as? [CGDisplayMode] else { return }
        
        // 过滤和去重显示模式
        var bestModes: [String: DisplayMode] = [:]
        
        // 筛选出符合条件的模式
        for mode in modes {
            // 排除无效的模式
            guard mode.isUsableForDesktopGUI() else { continue }
            
            // 逻辑宽度
            let logicW = mode.width
            // 逻辑高度
            let logicH = mode.height
            // 物理像素宽度
            let pixelW = mode.pixelWidth
            
            // 判断是否为 HiDIP 模式
            let isHiDPI = pixelW > logicW
            
            // 判断是否为高分辨率原生模式
            let isHighResNative = logicW >= 3840
            
            // 仅保留 HiDPI 模式或高分辨率原生模式
            if !isHiDPI && !isHighResNative { continue }
            
            // 创建分辨率
            let key = "\(logicW)x\(logicH)"
            let candidate = DisplayMode(width: logicW, height: logicH, pixelWidth: pixelW, mode: mode)
            
            // 选择分辨率像素密度最高的版本
            if let existing = bestModes[key] {
                if candidate.pixelWidth > existing.pixelWidth { bestModes[key] = candidate }
            } else {
                bestModes[key] = candidate
            }
        }
        
        // 排序结果
        self.availableModes = bestModes.values.sorted { $0.width > $1.width }
    }
    
    // 切换分辨率
    func setResolution(_ mode: DisplayMode) {
        // 获取主显示器 ID
        let mainDisplay = CGMainDisplayID()
        // 显示配置引用
        var config: CGDisplayConfigRef?
        
        // 开始显示配置
        if CGBeginDisplayConfiguration(&config) == .success {
            // 配置显示模式
            CGConfigureDisplayWithDisplayMode(config, mainDisplay, mode.mode, nil)
            // 更改配置
            CGCompleteDisplayConfiguration(config, .permanently)
            
            // 更新本地状态
            self.currentWidth = mode.width
        }
    }
}
