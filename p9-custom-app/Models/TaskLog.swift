//
//  TaskLog.swift
//  p9-custom-app
//
//  Created by Vidun Herath on 20/10/2026.
//

import Foundation

struct TaskLog: Codable, Identifiable, Hashable {
    let id: Int
    let taskId: Int
    let cycle: Int
    let dueDate: Date
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case cycle
        case dueDate = "due_date"
        case createdAt = "created_at"
    }
}

struct TaskLogInsert: Encodable {
    let taskId: Int
    let cycle: Int
    let dueDate: Date
    
    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case cycle
        case dueDate = "due_date"
    }
}
