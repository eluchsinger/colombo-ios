//
//  Supabase.swift
//  colombo-ios
//
//  Created by Esteban Luchsinger on 27.10.2024.
//


import Foundation
import OSLog
import Supabase

let supabase = SupabaseClient(
  supabaseURL: URL(string: "https://adoznwwgenufarkjghth.supabase.co")!,
  supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkb3pud3dnZW51ZmFya2pnaHRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTM2MDk3MDMsImV4cCI6MjAyOTE4NTcwM30.BkW6kKFV_XYIq8vUf-bQYthddrEeffJzSnUR7G2Yfgw",
  options: .init(
    global: .init(logger: AppLogger())
  )
)

struct AppLogger: SupabaseLogger {
  let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "supabase")

  func log(message: SupabaseLogMessage) {
    switch message.level {
    case .verbose:
      logger.log(level: .info, "\(message.description)")
    case .debug:
      logger.log(level: .debug, "\(message.description)")
    case .warning, .error:
      logger.log(level: .error, "\(message.description)")
    }
  }
}
