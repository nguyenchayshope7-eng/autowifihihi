import SwiftUI
import NetworkExtension

struct WiFiProfile: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var password: String
}

struct ContentView: View {
    @State private var profiles: [WiFiProfile] = []
    @State private var selectedID: UUID?
    @State private var ssid = ""
    @State private var password = ""
    @State private var status = "Sẵn sàng"
    @State private var showAdd = false

    private let storageKey = "wifi_profiles"

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    Image(systemName: "wifi")
                        .font(.system(size: 54))
                        .foregroundStyle(.blue)
                    Text("AUTO WIFI")
                        .font(.largeTitle.bold())
                    Text("Kết nối nhanh Wi‑Fi đã lưu")
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                if profiles.isEmpty {
                    ContentUnavailableView(
                        "Chưa có Wi‑Fi",
                        systemImage: "wifi.slash",
                        description: Text("Thêm một mạng Wi‑Fi để bắt đầu.")
                    )
                } else {
                    List {
                        Section("Wi‑Fi đã lưu") {
                            ForEach(profiles) { profile in
                                Button {
                                    selectedID = profile.id
                                } label: {
                                    HStack {
                                        Image(systemName: selectedID == profile.id ? "checkmark.circle.fill" : "wifi")
                                            .foregroundStyle(selectedID == profile.id ? .blue : .primary)
                                        VStack(alignment: .leading) {
                                            Text(profile.name)
                                                .foregroundStyle(.primary)
                                            Text(selectedID == profile.id ? "Đã chọn" : "Nhấn để chọn")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                            .onDelete(perform: delete)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .frame(maxHeight: 280)
                }

                Button {
                    connectSelected()
                } label: {
                    Label("KẾT NỐI WIFI", systemImage: "wifi")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedProfile == nil)

                Text(status)
                    .font(.subheadline)
                    .foregroundStyle(status.hasPrefix("Lỗi") ? .red : .secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.horizontal)
            .navigationTitle("Auto WiFi")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        ssid = ""
                        password = ""
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddWiFiView { name, pass in
                    profiles.append(WiFiProfile(name: name, password: pass))
                    saveProfiles()
                    selectedID = profiles.last?.id
                    showAdd = false
                    status = "Đã lưu \(name)"
                }
                .presentationDetents([.medium])
            }
            .onAppear {
                loadProfiles()
            }
        }
    }

    private var selectedProfile: WiFiProfile? {
        profiles.first { $0.id == selectedID }
    }

    private func connectSelected() {
        guard let profile = selectedProfile else {
            status = "Lỗi: Chưa chọn Wi‑Fi"
            return
        }

        status = "Đang yêu cầu kết nối \(profile.name)…"

        let config = NEHotspotConfiguration(
            ssid: profile.name,
            passphrase: profile.password,
            isWEP: false
        )
        config.joinOnce = false

        NEHotspotConfigurationManager.shared.apply(config) { error in
            DispatchQueue.main.async {
                if let error = error {
                    status = "Lỗi: \(error.localizedDescription)"
                } else {
                    status = "Đã gửi yêu cầu kết nối \(profile.name). iOS có thể hiện hộp thoại xác nhận."
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        profiles.remove(atOffsets: offsets)
        if let selectedID, !profiles.contains(where: { $0.id == selectedID }) {
            self.selectedID = profiles.first?.id
        }
        saveProfiles()
    }

    private func saveProfiles() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([WiFiProfile].self, from: data) {
            profiles = saved
            selectedID = saved.first?.id
        }
    }
}

struct AddWiFiView: View {
    let onSave: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var ssid = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Thông tin Wi‑Fi") {
                    TextField("Tên Wi‑Fi (SSID)", text: $ssid)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("Mật khẩu", text: $password)
                }

                Section {
                    Button("Lưu Wi‑Fi") {
                        let name = ssid.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        onSave(name, password)
                    }
                    .disabled(ssid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Thêm Wi‑Fi")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Hủy") { dismiss() }
                }
            }
        }
    }
}
