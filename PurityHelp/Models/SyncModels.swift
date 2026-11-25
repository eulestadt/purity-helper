//
//  SyncModels.swift
//

import Foundation
import SwiftData

@Model
final class ServerDoc {
    var key: String
    var payload: String
    var deleted: Bool

    init(key: String, payload: String, deleted: Bool) {
        self.key = key
        self.payload = payload
        self.deleted = deleted
    }
}

@Model
final class OutboxItem {
    var mutationId: Int64
    var name: String
    var argsJSON: String

    init(mutationId: Int64, name: String, argsJSON: String) {
        self.mutationId = mutationId
        self.name = name
        self.argsJSON = argsJSON
    }
}

@Model
final class SyncMeta {
    var singleton: String
    var clientId: String
    var cookie: Int64
    var nextMutationId: Int64
    var baseURL: String
    var email: String

    init(clientId: String) {
        singleton = "meta"
        self.clientId = clientId
        cookie = 0
        nextMutationId = 1
        baseURL = ""
        email = ""
    }
}
