//
//  FirestoreManager.swift
//  BrioCheck
//
//  Created by Abosh Upadhyaya on 5/30/25.
//

import FirebaseFirestore

class FirestoreManager: ObservableObject {
    private let db = Firestore.firestore()
    private var collection: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "America/Los_Angeles")! // Force Seattle time
        formatter.dateFormat = "yyyy-MM-dd"
        return "daily/\(formatter.string(from: Date()))/players"
    }	

    func save(player: Player) {
        db.collection(collection).document(player.name).setData(player.toDict()) { error in
            if let error = error {
                print("Error saving player: \(error)")
            } else {
                print("Successfully saved player: \(player.name) with status: \(player.status)")
            }
        }
    }

    func listenForPlayers(completion: @escaping ([Player]) -> Void) {
        db.collection(collection).addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Error fetching players: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            let players = documents.compactMap { Player.fromDict($0.data()) }
            completion(players)
        }
    }
}
