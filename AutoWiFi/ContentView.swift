import SwiftUI
import NetworkExtension

struct WiFiProfile: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var password: String

    init(
        id: UUID = UUID(),
        name: String,
        password: String
    ) {
        self.id = id
        self.name = name
        self.password = password
    }
}

struct ContentView: View {

    @State private var profiles: [WiFiProfile] = []

    @State private var showAddWiFi = false
    @State private var editingProfile: WiFiProfile?

    @State private var status = "Sẵn sàng"
    @State private var connectingID: UUID?

    private let storageKey = "wifi_profiles"

    var body: some View {
        NavigationStack {

            VStack(spacing: 0) {

                header

                if profiles.isEmpty {
                    emptyView
                } else {
                    wifiList
                }

                Spacer()

                statusView

                addButton
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)

            .sheet(isPresented: $showAddWiFi) {
                AddWiFiView { name, password in

                    addWiFi(
                        name: name,
                        password: password
                    )

                    showAddWiFi = false
                }
            }

            .sheet(item: $editingProfile) { profile in

                EditWiFiView(
                    profile: profile
                ) { name, password in

                    updateWiFi(
                        profile: profile,
                        name: name,
                        password: password
                    )

                    editingProfile = nil
                }
            }

            .onAppear {
                loadProfiles()
            }
        }
    }

    // MARK: - Header

    private var header: some View {

        VStack(spacing: 8) {

            Image(systemName: "wifi")
                .font(.system(size: 46))
                .foregroundStyle(.blue)

            Text("AutoWiFi")
                .font(.system(size: 30, weight: .bold))

            Text("Kết nối Wi-Fi nhanh")
                .font(.subheadline)
                .foregroundStyle(.secondary)

        }
        .frame(maxWidth: .infinity)
        .padding(.top, 25)
        .padding(.bottom, 20)
        .background(Color(.systemBackground))
    }

    // MARK: - Empty

    private var emptyView: some View {

        VStack(spacing: 15) {

            Spacer()

            Image(systemName: "wifi.slash")
                .font(.system(size: 55))
                .foregroundStyle(.secondary)

            Text("Chưa có Wi-Fi")
                .font(.title3.bold())

            Text("Thêm Wi-Fi một lần.\nSau đó chỉ cần bấm để kết nối.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - WiFi List

    private var wifiList: some View {

        List {

            Section {

                ForEach(profiles) { profile in

                    WiFiRow(
                        profile: profile,
                        isConnecting: connectingID == profile.id,
                        onConnect: {
                            connect(profile)
                        },
                        onEdit: {
                            editingProfile = profile
                        },
                        onDelete: {
                            delete(profile)
                        }
                    )
                }
            } header: {

                Text("Wi-Fi đã lưu")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Status

    private var statusView: some View {

        Text(status)
            .font(.subheadline)
            .multilineTextAlignment(.center)
            .foregroundStyle(
                status.hasPrefix("Lỗi")
                ? .red
                : .secondary
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
    }

    // MARK: - Add Button

    private var addButton: some View {

        Button {

            showAddWiFi = true

        } label: {

            Label(
                "THÊM WI-FI",
                systemImage: "plus"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
        }
        .buttonStyle(.borderedProminent)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Add WiFi

    private func addWiFi(
        name: String,
        password: String
    ) {

        let cleanName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanName.isEmpty else {
            return
        }

        let profile = WiFiProfile(
            name: cleanName,
            password: password
        )

        profiles.append(profile)

        saveProfiles()

        status = "Đã lưu Wi-Fi \(cleanName)"
    }

    // MARK: - Update

    private func updateWiFi(
        profile: WiFiProfile,
        name: String,
        password: String
    ) {

        let cleanName = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanName.isEmpty else {
            return
        }

        guard let index = profiles.firstIndex(
            where: { $0.id == profile.id }
        ) else {
            return
        }

        profiles[index].name = cleanName
        profiles[index].password = password

        saveProfiles()

        status = "Đã cập nhật \(cleanName)"
    }

    // MARK: - Delete

    private func delete(
        _ profile: WiFiProfile
    ) {

        profiles.removeAll {
            $0.id == profile.id
        }

        saveProfiles()

        status = "Đã xóa \(profile.name)"
    }

    // MARK: - Connect

    private func connect(
        _ profile: WiFiProfile
    ) {

        connectingID = profile.id

        status = "Đang kết nối \(profile.name)…"

        let configuration = NEHotspotConfiguration(
            ssid: profile.name,
            passphrase: profile.password,
            isWEP: false
        )

        configuration.joinOnce = false

        NEHotspotConfigurationManager.shared.apply(
            configuration
        ) { error in

            DispatchQueue.main.async {

                connectingID = nil

                if let error = error {

                    status =
                        "Lỗi: \(error.localizedDescription)"

                } else {

                    status =
                        "Đã gửi yêu cầu kết nối \(profile.name)"
                }
            }
        }
    }

    // MARK: - Save

    private func saveProfiles() {

        guard let data = try? JSONEncoder().encode(
            profiles
        ) else {
            return
        }

        UserDefaults.standard.set(
            data,
            forKey: storageKey
        )
    }

    // MARK: - Load

    private func loadProfiles() {

        guard let data =
            UserDefaults.standard.data(
                forKey: storageKey
            )
        else {
            return
        }

        guard let saved =
            try? JSONDecoder().decode(
                [WiFiProfile].self,
                from: data
            )
        else {
            return
        }

        profiles = saved
    }
}

// MARK: - WiFi Row

struct WiFiRow: View {

    let profile: WiFiProfile
    let isConnecting: Bool

    let onConnect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {

        VStack(spacing: 12) {

            Button {

                onConnect()

            } label: {

                HStack(spacing: 14) {

                    Image(systemName: "wifi")
                        .font(.system(size: 24))
                        .foregroundStyle(.blue)
                        .frame(width: 35)

                    VStack(
                        alignment: .leading,
                        spacing: 4
                    ) {

                        Text(profile.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(
                            isConnecting
                            ? "Đang kết nối…"
                            : "Nhấn để kết nối"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if isConnecting {

                        ProgressView()

                    } else {

                        Image(
                            systemName:
                                "chevron.right"
                        )
                        .foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: 10) {

                Button {

                    onConnect()

                } label: {

                    Label(
                        "Kết nối",
                        systemImage: "wifi"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {

                    onEdit()

                } label: {

                    Image(
                        systemName: "gearshape"
                    )
                    .frame(width: 45)
                }
                .buttonStyle(.bordered)

                Button {

                    onDelete()

                } label: {

                    Image(
                        systemName: "trash"
                    )
                    .frame(width: 45)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Add WiFi

struct AddWiFiView: View {

    let onSave: (
        String,
        String
    ) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @State private var ssid = ""
    @State private var password = ""

    var body: some View {

        NavigationStack {

            Form {

                Section(
                    "Thông tin Wi-Fi"
                ) {

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

                    Button {

                        let name =
                            ssid.trimmingCharacters(
                                in:
                                    .whitespacesAndNewlines
                            )

                        guard !name.isEmpty else {
                            return
                        }

                        onSave(
                            name,
                            password
                        )

                    } label: {

                        Text("Lưu Wi-Fi")
                            .frame(
                                maxWidth: .infinity
                            )
                    }
                }
            }

            .navigationTitle(
                "Thêm Wi-Fi"
            )

            .navigationBarTitleDisplayMode(
                .inline
            )

            .toolbar {

                ToolbarItem(
                    placement:
                        .topBarLeading
                ) {

                    Button("Hủy") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Edit WiFi

struct EditWiFiView: View {

    let profile: WiFiProfile

    let onSave: (
        String,
        String
    ) -> Void

    @Environment(\.dismiss)
    private var dismiss

    @State private var ssid: String
    @State private var password: String

    init(
        profile: WiFiProfile,
        onSave: @escaping (
            String,
            String
        ) -> Void
    ) {

        self.profile = profile
        self.onSave = onSave

        _ssid = State(
            initialValue: profile.name
        )

        _password = State(
            initialValue: profile.password
        )
    }

    var body: some View {

        NavigationStack {

            Form {

                Section(
                    "Cấu hình Wi-Fi"
                ) {

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

                    Button {

                        let name =
                            ssid.trimmingCharacters(
                                in:
                                    .whitespacesAndNewlines
                            )

                        guard !name.isEmpty else {
                            return
                        }

                        onSave(
                            name,
                            password
                        )

                    } label: {

                        Text("Lưu thay đổi")
                            .frame(
                                maxWidth: .infinity
                            )
                    }
                }
            }

            .navigationTitle(
                "Đổi cấu hình"
            )

            .navigationBarTitleDisplayMode(
                .inline
            )

            .toolbar {

                ToolbarItem(
                    placement:
                        .topBarLeading
                ) {

                    Button("Hủy") {
                        dismiss()
                    }
                }
            }
        }
    }
}
