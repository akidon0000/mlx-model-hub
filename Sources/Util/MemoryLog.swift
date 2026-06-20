import Foundation
import os

/// 計測ログ用の軽量ユーティリティ。
/// メモリクラッシュ調査のため、RSS(MB) を要所で出力する。
enum MemoryLog {
    private static let logger = Logger(subsystem: "com.akidon0000.mlxmodelhub", category: "memory")

    /// 現在の常駐メモリ使用量(MB)。取得失敗時は nil。
    static func residentMB() -> Double? {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return nil }
        return Double(info.phys_footprint) / 1024.0 / 1024.0
    }

    static func log(_ tag: String, _ detail: String = "") {
        let rss = residentMB().map { String(format: "%.1f", $0) } ?? "?"
        logger.log("[\(rss, privacy: .public)MB] \(tag, privacy: .public) \(detail, privacy: .public)")
    }
}
