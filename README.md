# Auto WiFi — iOS Xcode Project

## Chức năng
- Thêm nhiều Wi‑Fi (SSID + mật khẩu)
- Lưu danh sách Wi‑Fi trên iPhone
- Chọn Wi‑Fi
- Bấm một nút để yêu cầu iOS kết nối
- Xóa Wi‑Fi đã lưu

## Tạo project Xcode
1. Mở Xcode trên Mac.
2. File → New → Project → iOS → App.
3. Product Name: `AutoWiFi`
4. Interface: SwiftUI
5. Language: Swift.
6. Thay `AutoWiFiApp.swift` và `ContentView.swift` bằng các file trong thư mục này.
7. Thêm `Info.plist` nếu cần và đặt target iOS phù hợp.
8. Chọn iPhone thật → Sign & Capabilities → chọn Team → Run.

## Lưu ý
iOS kiểm soát việc tham gia Wi‑Fi. Ứng dụng không thể ép iPhone kết nối Wi‑Fi hoàn toàn âm thầm trong mọi trường hợp; hệ thống có thể yêu cầu xác nhận hoặc từ chối tùy trạng thái mạng/quyền.
