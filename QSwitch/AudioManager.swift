import Foundation
import CoreAudio
import Combine

// 音频设备
struct AudioDevice: Identifiable, Hashable {
    // CoreAudio 中设备的唯一 ID
    let id: AudioObjectID
    // 显示的设备名字
    let name: String
    // 音频设备的 UID
    let uid: String
}

// 音频预设配置
// 储存输入输出设备的配置，用来快速切换
struct AudioPreset: Identifiable, Codable {
    // 预设的唯一标识
    var id = UUID()
    // 预设名称
    let name: String
    // 输入设备的 UID
    let inputDeviceUID: String
    // 输出设备的 UID
    let outputDeviceUID: String
}

// 音频管理
class AudioManager: ObservableObject {
    // 所有输入设备列表
    @Published var inputDevices: [AudioDevice] = []
    // 所有输出设备列表
    @Published var outputDevices: [AudioDevice] = []
    // 当前默认输入设备 ID
    @Published var currentInputID: AudioObjectID?
    // 当前默认输出设备 ID
    @Published var currentOutputID: AudioObjectID?
    
    // 预设配置数组
    @Published var presets: [AudioPreset] = [] {
        didSet { savePresets() }
    }
    
    init() {
        // 扫描并加载所有音频设备
        refreshDevices()
        // 加载保存的预设配置
        loadPresets()
    }
    
    // 刷新设备列表
    func refreshDevices() {
        self.inputDevices = getDevices(isInput: true)
        self.outputDevices = getDevices(isInput: false)
        checkCurrentSystemDevices()
    }
    
    // 更新当前系统默认设备
    func checkCurrentSystemDevices() {
        self.currentInputID = getDefaultDeviceID(isInput: true)
        self.currentOutputID = getDefaultDeviceID(isInput: false)
    }
    
    // 获取系统默认设备的 ID
    private func getDefaultDeviceID(isInput: Bool) -> AudioObjectID? {
        var address = AudioObjectPropertyAddress(
            mSelector: isInput ? kAudioHardwarePropertyDefaultInputDevice : kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = kAudioObjectUnknown
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        
        // 从 CoreAudio 系统对象获取属性数据
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),&address, 0, nil, &size, &deviceID)
        
        return status == noErr ? deviceID : nil
    }
    
    // 获取指定类型的所有音频设备
    private func getDevices(isInput: Bool) -> [AudioDevice] {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        
        // 获取设备列表的数据大小
        let status = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize)

        guard status == noErr else { return [] }
        
        // 计算设备数量
        let deviceCount = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var deviceIDs = [AudioObjectID](repeating: 0, count: deviceCount)
        
        // 获取实际的设备 ID 列表
        _ = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize, &deviceIDs)
        
        var devices: [AudioDevice] = []
        
        // 筛选出符合条件的设备
        for id in deviceIDs {
            // 构建属性地址，查询设备的音频流
            var scopeAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreams,
                mScope: isInput ? kAudioObjectPropertyScopeInput : kAudioObjectPropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            var streamSize: UInt32 = 0
            
            // 获取音频流数据的大小
            AudioObjectGetPropertyDataSize(id, &scopeAddress, 0, nil, &streamSize)

            if streamSize > 0 {
                let name = getDeviceStringProperty(deviceID: id, selector: kAudioObjectPropertyName)
                let uid = getDeviceStringProperty(deviceID: id, selector: kAudioDevicePropertyDeviceUID)
                devices.append(AudioDevice(id: id, name: name, uid: uid))
            }
        }
        return devices
    }
    
    
    /// 获取设备的字符串属性
    /// - Parameters:
    ///   - deviceID: 设备的 AudioObjectID
    ///   - selector: 要查询的属性选择器
    /// - Returns: 属性值字符串，如果获取失败返回 Unknown
    private func getDeviceStringProperty(deviceID: AudioObjectID, selector: AudioObjectPropertySelector) -> String {
        var address = AudioObjectPropertyAddress(mSelector: selector, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        var stringRef: CFString? = nil
        var size = UInt32(MemoryLayout<CFString?>.size)
        
        // 针获取字符串属性数据
        let status = withUnsafeMutablePointer(to: &stringRef) { ptr in
            AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, ptr)
        }
        
        return (status == noErr && stringRef != nil) ? (stringRef! as String) : "Unknown"
    }
    
    /// 设置系统默认音频设备
    /// - Parameters:
    ///   - id: 要设置的设备 ID
    ///   - isInput: true 表示设置输入设备，false 表示设置输出设备
    func setDevice(id: AudioObjectID, isInput: Bool) {
        var address = AudioObjectPropertyAddress(
            mSelector: isInput ? kAudioHardwarePropertyDefaultInputDevice : kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceId = id
        let size = UInt32(MemoryLayout<AudioObjectID>.size)
        
        // 设置默认设备
        AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, size, &deviceId)
        
        // 更新本地状态
        if isInput { currentInputID = id } else { currentOutputID = id }
    }
    
    // 将当前系统音频设备配置保存为预设
    func saveCurrentAsPreset(name: String) {
        // 获取最新的系统默认设备
        checkCurrentSystemDevices()
        
        if let inID = currentInputID, let outID = currentOutputID,
           let inDevice = inputDevices.first(where: { $0.id == inID }), // 查找对应的输入设备对象
           let outDevice = outputDevices.first(where: { $0.id == outID }) { // 查找对应的输出设备对象
            
            // 创建新预设，使用设备的 UID
            let newPreset = AudioPreset(name: name, inputDeviceUID: inDevice.uid, outputDeviceUID: outDevice.uid)
            
            // 添加到预设列表
            presets.append(newPreset)
        }
    }
    
    // 应用预设配置
    func applyPreset(_ preset: AudioPreset) {
        // 根据预设中的输入设备 UID 查找对应的设备
        if let inDevice = inputDevices.first(where: { $0.uid == preset.inputDeviceUID }) {
            setDevice(id: inDevice.id, isInput: true)
        }
        
        // 根据预设中的输出设备 UID 查找对应的设备
        if let outDevice = outputDevices.first(where: { $0.uid == preset.outputDeviceUID }) {
            setDevice(id: outDevice.id, isInput: false)
        }
    }
    
    // 将预设数组保存到本地
    private func savePresets() {
        if let encoded = try? JSONEncoder().encode(presets) { UserDefaults.standard.set(encoded, forKey: "AudioPresets") }
    }
    
    // 加载本地配置
    private func loadPresets() {
        if let data = UserDefaults.standard.data(forKey: "AudioPresets"), let decoded = try? JSONDecoder().decode([AudioPreset].self, from: data) { presets = decoded }
    }
}
