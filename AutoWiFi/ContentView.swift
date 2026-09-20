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
    @State private var status = "Sẵn sàng"
    @State private var showAdd = false

    private let storageKey = "wifi_profiles"

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                headerView

                wifiListView

                connectButton

                statusView

                Spacer()
            }
            .padding(.horizontal)
            .navigationTitle("Auto WiFi")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddWiFiView { name, password in
                    addProfile(name: name, password: password)
                }
                .presentationDetents([.medium])
            }
            .onAppear {
                loadProfiles()
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: 6) {
            Image(systemName: "wifi")
                .font(.system(size: 54))
                .foregroundStyle(.blue)

            Text("AUTO WIFI")
                .font(.largeTitle.bold())

            Text("Kết nối nhanh Wi-Fi đã lưu")
                .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
    }

    @ViewBuilder
    private var wifiListView: some View {
       if profiles.isEmpty {
    VStack(spacing: 10) {
        Image(systemName: "wifi.slash")
            .font(.system(size: 40))
            .foregroundStyle(.secondary)

        Text("Chưa có Wi-Fi")
            .font(.headline)

        Text("Nhấn dấu + để thêm mạng Wi-Fi.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding()
} else {
            List {
                Section("Wi-Fi đã lưu") {
                    ForEach(profiles) { profile in
                        wifiRow(profile)
                    }
                    .onDelete(perform: delete)
                }
            }
            .listStyle(.insetGrouped)
            .frame(maxHeight: 280)
        }
    }

    private func wifiRow(_ profile: WiFiProfile) -> some View {
        Button {
            selectedID = profile.id
        } label: {
            HStack {
                Image(
                    systemName: selectedID == profile.id
                    ? "checkmark.circle.fill"
                    : "wifi"
                )
                .foregroundStyle(
                    selectedID == profile.id ? .blue : .primary
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(profile.name)
                        .foregroundStyle(.primary)

                    Text(
                        selectedID == profile.id
                        ? "Đã chọn"
                        : "Nhấn để chọn"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }

    private var connectButton: some View {
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
    }

    private var statusView: some View {
        Text(status)
            .font(.subheadline)
            .foregroundStyle(
                status.hasPrefix("Lỗi") ? .red : .secondary
            )
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }

    private var selectedProfile: WiFiProfile? {
        profiles.first {
            $0.id == selectedID
        }
    }

    private func addProfile(name: String, password: String) {
        let profile = WiFiProfile(
            name: name,
            password: password
        )

        profiles.append(profile)
        selectedID = profile.id
        saveProfiles()

        status = "Đã lưu \(name)"
        showAdd = false
    }

    private func connectSelected() {
        guard let profile = selectedProfile else {
            status = "Lỗi: Chưa chọn Wi-Fi"
            return
        }

        status = "Đang yêu cầu kết nối \(profile.name)…"

        let configuration = NEHotspotConfiguration(
            ssid: profile.name,
            passphrase: profile.password,
            isWEP: false
        )

        configuration.joinOnce = false

        NEHotspotConfigurationManager.shared.apply(configuration) {
            error in

            DispatchQueue.main.async {
                if let error = error {
                    status = "Lỗi: \(error.localizedDescription)"
                } else {
                    status =
                        "Đã gửi yêu cầu kết nối \(profile.name). iOS có thể hiện hộp thoại xác nhận."
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        profiles.remove(atOffsets: offsets)

        if let selectedID {
            let exists = profiles.contains {
                $0.id == selectedID
            }

            if !exists {
                self.selectedID = profiles.first?.id
            }
        }

        saveProfiles()
    }

    private func saveProfiles() {
        guard let data = try? JSONEncoder().encode(profiles) else {
            return
        }

        UserDefaults.standard.set(
            data,
            forKey: storageKey
        )
    }

    private func loadProfiles() {
        guard let data = UserDefaults.standard.data(
            forKey: storageKey
        ) else {
            return
        }

        guard let saved = try? JSONDecoder().decode(
            [WiFiProfile].self,
            from: data
        ) else {
            return
        }

        profiles = saved
        selectedID = saved.first?.id
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
                Section("Thông tin Wi-Fi") {
                    TextField(
                        "Tên Wi-Fi (SSID)",
                        text: $ssid
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                    SecureField(
                        "Mật khẩu",
                        text: $password
                    )
                }

                Section {
                    Button("Lưu Wi-Fi") {
                        let name = ssid
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            )

                        guard !name.isEmpty else {
                            return
                        }

                        onSave(name, password)
                    }
                    .disabled(
                        ssid.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                }
            }
            .navigationTitle("Thêm Wi-Fi")
            .toolbar {
                ToolbarItem(
                    placement: .topBarLeading
                ) {
                    Button("Hủy") {
                        dismiss()
                    }
                }
            }
        }
    }
}
