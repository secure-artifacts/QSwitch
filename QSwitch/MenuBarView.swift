import SwiftUI

struct MenuBarView: View {
    // 显示器管理器
    @ObservedObject var displayManager: DisplayManager
    // 音频管理器
    @ObservedObject var audioManager: AudioManager
    // 开机启动管理器
    @ObservedObject var launchManager: LaunchAtLoginManager
    // 新预设名称输入框的文本绑定
    @State private var presetName: String = ""
    // 当前鼠标悬停的预设项 ID
    @State private var hoveredPresetId: UUID?
    
    // 字体设置
    // 标签字体
    let labelFont = Font.system(size: 13, weight: .medium)
    // 内容字体
    let contentFont = Font.system(size: 14, weight: .regular)
    // 标题字体
    let headerFont = Font.system(size: 18, weight: .bold)
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部区域
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("title")
                        .font(headerFont)
                        .foregroundColor(.primary)

                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            
            Divider()
                .opacity(0.3)
            
            // 中间内容区域
            VStack(spacing: 16) {
                // 卡片标题
                CardView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "display")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
                            
                            Text("resolution")
                                .font(labelFont)
                                .foregroundColor(.primary)
                        }
                        
                        // 分辨率选择菜单
                        Menu {
                            // 获取分辨率清单，生成菜单项
                            ForEach(displayManager.availableModes) { mode in
                                Button {
                                    // 点击时切换分辨率
                                    displayManager.setResolution(mode)
                                } label: {
                                    // 当前激活的分辨率显示勾选标记
                                    if mode.width == displayManager.currentWidth {
                                        Text("✓ \(mode.title)").font(contentFont)
                                    } else {
                                        Text(mode.title).font(contentFont)
                                    }
                                }
                            }
                        } label: {
                            // 菜单按钮的显示内容
                            HStack {
                                // 查找当前激活的分辨率模式
                                let current = displayManager.availableModes.first(where: { $0.width == displayManager.currentWidth })
                                Text(current?.title ?? "选择分辨率...")
                                    .font(contentFont)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(nsColor: .controlBackgroundColor))
                                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                        }
                        .menuStyle(.borderlessButton)
                    }
                }
                
                // 音频控制卡片
                CardView {
                    VStack(alignment: .leading, spacing: 14) {
                        // 卡片标题
                        HStack(spacing: 8) {
                            Image(systemName: "waveform.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.purple)
                            
                            Text("audio")
                                .font(labelFont)
                                .foregroundColor(.primary)
                        }
                        
                        // 输入设备
                        AudioDeviceRow(
                            icon: "mic.fill", // 麦克风图标
                            iconColor: .orange,
                            devices: audioManager.inputDevices, // 输入设备列表
                            currentID: audioManager.currentInputID, // 当前选中的输入设备 ID
                            onSelect: { deviceId in
                                audioManager.setDevice(id: deviceId, isInput: true) // 切换输出设备
                            }
                        )
                        
                        // 输出设备
                        AudioDeviceRow(
                            icon: "speaker.wave.2.fill", // 扬声器图标
                            iconColor: .green,
                            devices: audioManager.outputDevices, // 输出设备列表
                            currentID: audioManager.currentOutputID, // 当前选中的输出设备 ID
                            onSelect: { deviceId in
                                audioManager.setDevice(id: deviceId, isInput: false) // 切换输出设备
                            }
                        )
                    }
                }
                
                // 场景预设卡片
                CardView {
                    VStack(alignment: .leading, spacing: 12) {
                        // 卡片标题
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.orange)
                            
                            Text("presets.title")
                                .font(labelFont)
                                .foregroundColor(.primary)
                        }
                        
                        // 新建预设输入区域
                        HStack(spacing: 8) {
                            // 预设名称输入框
                            TextField("presets.placeholder", text: $presetName)
                                .textFieldStyle(CustomTextFieldStyle())
                                .font(contentFont)
                            
                            // 保存按钮
                            Button {
                                // 保存当前音频配置为预设
                                audioManager.saveCurrentAsPreset(name: presetName)
                                presetName = ""
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    // 输入框为空时显示灰色，有内容时显示蓝色
                                    .foregroundColor(presetName.isEmpty ? .secondary : .blue)
                            }
                            .buttonStyle(.plain)
                            // 输入框为空时禁用按钮
                            .disabled(presetName.isEmpty)
                        }
                        
                        // 预设列表
                        if !audioManager.presets.isEmpty {
                            VStack(spacing: 8) {
                                // 遍历所有预设
                                ForEach(audioManager.presets) { preset in
                                    PresetRow(
                                        preset: preset,
                                        isHovered: hoveredPresetId == preset.id, // 判断是否被悬停
                                        onApply: {
                                            audioManager.applyPreset(preset) // 应用预设
                                        },
                                        onDelete: {
                                            // 删除预设
                                            if let index = audioManager.presets.firstIndex(where: {$0.id == preset.id}) {
                                                audioManager.presets.remove(at: index)
                                            }
                                        }
                                    )
                                    // 监听鼠标悬停事件
                                    .onHover { isHovered in
                                        hoveredPresetId = isHovered ? preset.id : nil
                                    }
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .padding(20)
            
            // 底部区域
            VStack(spacing: 0) {
                Divider()
                    .opacity(0.3)
                
                HStack(spacing: 16) {
                    // 开机启动开关
                    Toggle(isOn: Binding(
                        get: { launchManager.isEnabled }, // 读取当前状态
                        set: { _ in launchManager.toggle() } // 切换状态
                    )) {
                        HStack(spacing: 6) {
                            Image(systemName: "power")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("launchAtLogin")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    
                    Spacer()
                    
                    // 退出按钮
                    Button {
                        NSApplication.shared.terminate(nil) // 终止应用程序
                    } label: {
                        HStack(spacing: 6) {
                            Text("quit")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.primary.opacity(0.05))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        }
        .frame(width: 380)
        // 垂直方向自适应高度，水平方向固定
        .fixedSize(horizontal: false, vertical: true)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            // 打开菜单时初始化数据
            displayManager.fetchModes() // 加载显示模式列表
            audioManager.refreshDevices() // 刷新音频设备列表
            launchManager.checkStatus() // 检查开机启动状态
        }
    }
}

// 卡片容器视图
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
    }
}

// 音频设备行组件
struct AudioDeviceRow: View {
    let icon: String
    let iconColor: Color
    // 设备列表
    let devices: [AudioDevice]
    // 当前选中的设备 ID
    let currentID: UInt32?
    // 选择设备时回调闭包
    let onSelect: (UInt32) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 16, alignment: .center)
            
            // 设备选择菜单
            Menu {
                // 获取全部设备，生成下拉菜单
                ForEach(devices) { device in
                    Button {
                        onSelect(device.id)
                    } label: {
                        // 当前选中的设备，显示勾选标记
                        Text((device.id == currentID ? "✓ " : "") + device.name)
                    }
                }
            } label: {
                HStack {
                    let current = devices.first(where: { $0.id == currentID })
                    Text(current?.name ?? "默认")
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .lineLimit(1) // 单行显示，超长文本截断
                    Spacer()
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
                )
            }
            .menuStyle(.borderlessButton)
        }
    }
}

// 场景预设行视图
struct PresetRow: View {
    // 预设数据
    let preset: AudioPreset
    // 是否被鼠标悬停
    let isHovered: Bool
    // 应用预设的回调
    let onApply: () -> Void
    // 删除预设的回调
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // 应用预设
            Button(action: onApply) {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                    
                    Text(preset.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.leading, 4)
                    
                    Spacer()
                }
                .padding(.vertical, 10)
                .padding(.leading, 12)
                .padding(.trailing, 8)
                .contentShape(Rectangle()) // 将整个矩形区域设置为可点击区域
            }
            .buttonStyle(.plain)
            
            // 删除按钮
            Button(action: onDelete) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 12))
                // 悬停时显示红色，否则显示灰色
                    .foregroundColor(isHovered ? .red : .secondary)
                    .padding(10)
            }
            .buttonStyle(.plain)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? Color.blue.opacity(0.08) : Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
        )
    }
}

// 自定义文本框样式
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
            )
    }
}
