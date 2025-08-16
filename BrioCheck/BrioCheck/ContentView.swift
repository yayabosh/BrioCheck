import SwiftUI

struct Player: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var status: Status
    var reason: String?
    var time: Date? = nil

    enum Status: String, Codable {
        case coming
        case maybe
        case notComing
    }

    func toDict() -> [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "status": status.rawValue,
            "reason": reason ?? NSNull()
        ]
        if let time = time {
            let formatter = ISO8601DateFormatter()
            dict["time"] = formatter.string(from: time)
        }
        return dict
    }

    static func fromDict(_ dict: [String: Any]) -> Player? {
        guard let name = dict["name"] as? String,
              let statusString = dict["status"] as? String,
              let status = Status(rawValue: statusString) else {
            return nil
        }
        let reason = dict["reason"] as? String
        var time: Date? = nil
        if let timeString = dict["time"] as? String {
            let formatter = ISO8601DateFormatter()
            time = formatter.date(from: timeString)
        }
        return Player(name: name, status: status, reason: reason, time: time)
    }
    
    static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.status == rhs.status &&
        lhs.reason == rhs.reason &&
        lhs.time == rhs.time
    }
}

extension Player.Status {
    var sortOrder: Int {
        switch self {
        case .coming: return 0
        case .maybe: return 1
        case .notComing: return 2
        }
    }
}

struct LogoView: View {
    var size: CGFloat = 80

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Text("🏀")
                .font(.system(size: size))
                .shadow(radius: 2)
            Text("✅")
                .font(.system(size: size * 0.35))
                .offset(x: size * 0.005, y: size * 0.005)
        }
        .padding(.bottom, 20)
    }
}

struct SplashView: View {
    @Binding var isActive: Bool

    var body: some View {
        VStack {
            Spacer()
            LogoView()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    isActive = false
                }
            }
        }
    }
}

struct HowToUseView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Tap the 🏀✅ logo at the top to reset your name.", systemImage: "person.crop.circle.badge.xmark")
                    Label("Choose an emoji to set your status:", systemImage: "hand.tap")
                    Text("✅ = Coming\n🤔 = Maybe\n🦆 = Not Coming")
                        .padding(.leading, 24)
                        .foregroundColor(.secondary)
                    
                    Label("If you’re coming, set your arrival time with the clock picker.", systemImage: "clock")
                }
                .padding()
            }
            .navigationTitle("How to Use")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ContentView: View {
    @State private var name: String = ""
    @State private var nameSet: Bool = false
    @State private var arrivalTime: Date = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date())! // 5:00 PM
    @State private var players: [Player] = []
    @State private var showSplash = true  // Splash screen control
    @StateObject var firestore = FirestoreManager()
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        Group {
            if showSplash {
                SplashView(isActive: $showSplash)
            } else {
                mainContent
            }
        }
        .onAppear {
            // Auto-sign in if name was previously saved
            if let savedName = UserDefaults.standard.string(forKey: "playerName") {
                name = savedName
                nameSet = true
            }
            firestore.listenForPlayers { loadedPlayers in
                players = loadedPlayers
            }
        }
    }

    var mainContent: some View {
        ZStack {
            LinearGradient(
                colors: [Color.white, Color(red: 0.7, green: 0.85, blue: 0.85)],
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                if !nameSet {
                    LogoView()
                    
                    VStack {
                        VStack(spacing: 4) {
                            Text("Welcome to")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            Text("Brio Check")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                        }
                        .padding(.bottom, 10)
                        
                        TextField("Enter your name", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.vertical, 10)
                            .padding(.horizontal)
                            .disableAutocorrection(true)
                            .focused($isNameFieldFocused)
                        
                        Button("Continue") {
                            if let existingPlayer = players.first(where: { $0.name == name }), let existingTime = existingPlayer.time {
                                arrivalTime = existingTime
                            }
                            nameSet = true

                            // Save name to UserDefaults
                            UserDefaults.standard.set(name, forKey: "playerName")
                        }
                        .padding()
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isNameFieldFocused = true
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Button(action: {
                            nameSet = false
                        }) {
                            LogoView(size: 32)
                        }
                        .buttonStyle(PlainButtonStyle()) // Removes default button styling
                        
                        Text("Today is \(formattedDate())")
                            .font(.subheadline)
                        
                        Text("Today’s Players")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 12) {
                            if players.isEmpty {
                                Text("Nobody’s coming yet 😢")
                                    .foregroundColor(.gray)
                            } else {
                                let sortedPlayers = players.sorted {
                                    if $0.status.sortOrder == $1.status.sortOrder {
                                        return $0.name.lowercased() < $1.name.lowercased()
                                    } else {
                                        return $0.status.sortOrder < $1.status.sortOrder
                                    }
                                }
                                ForEach(sortedPlayers) { player in
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(player.name)
                                                .fontWeight(.medium)
                                            Spacer(minLength: 8)
                                            Text(statusEmoji(for: player.status))
                                        }
                                        if let time = player.time, player.status == .coming {
                                            Text("Arriving at \(formattedTime(from: time))")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    Divider()
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        HStack(spacing: 10) {
                            if [.coming].contains(players.first(where: { $0.name == name })?.status) {
                                VStack(spacing: 4) {
                                    Text("When are you coming?")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    DatePicker("Arrival Time", selection: $arrivalTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .padding(.horizontal)
                                        .onChange(of: arrivalTime) { _, newTime in
                                            if let index = players.firstIndex(where: { $0.name == name }) {
                                                players[index].time = newTime
                                                firestore.save(player: players[index])
                                            }
                                        }
                                }
                                .transition(.opacity)
                            }
                            
                            Button(action: {
                                updateStatus(.coming)
                            }) {
                                Text("✅")
                                    .bold()
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green.opacity(0.5))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(players.first(where: { $0.name == name })?.status == .coming ? Color.green.opacity(0.9) : Color.clear, lineWidth: 2)
                                    )
                            }
                            
                            Button(action: {
                                updateStatus(.maybe)
                            }) {
                                Text("🤔")
                                    .bold()
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.orange.opacity(0.5))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(players.first(where: { $0.name == name })?.status == .maybe ? Color.orange.opacity(0.9) : Color.clear, lineWidth: 2)
                                    )
                            }
                            
                            Button(action: {
                                updateStatus(.notComing)
                            }) {
                                Text("🦆")
                                    .bold()
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.5))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(players.first(where: { $0.name == name })?.status == .notComing ? Color.red.opacity(0.9) : Color.clear, lineWidth: 2)
                                    )
                            }
                        }
                        .padding(.horizontal)
                        .animation(.easeInOut, value: players)
                    }
                    .padding(.top)
                }
                
            }
        }
        .onAppear {
            firestore.listenForPlayers { loadedPlayers in
                print("Loaded players:", loadedPlayers)
                players = loadedPlayers
            }
        }
    }

    func updateStatus(_ status: Player.Status) {
        if let index = players.firstIndex(where: { $0.name == name }) {
            players[index].status = status
            players[index].time = arrivalTime
            firestore.save(player: players[index])
        } else {
            let newPlayer = Player(name: name, status: status, reason: nil, time: arrivalTime)
            players.append(newPlayer)
            firestore.save(player: newPlayer)
        }
    }

    func statusEmoji(for status: Player.Status) -> String {
        switch status {
        case .coming: return "✅"
        case .maybe: return "🤔"
        case .notComing: return "🦆"
        }
    }

    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }

    func formattedTime(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    ContentView()
}
