# AutoWiFi — GitHub Actions IPA Builder

## Build bằng Windows, không cần Mac

1. Tạo repository GitHub mới.
2. Upload toàn bộ thư mục project này lên repository.
3. Vào tab **Actions**.
4. Chọn **Build AutoWiFi IPA**.
5. Bấm **Run workflow**.
6. Chờ build xong.
7. Mở workflow run vừa hoàn thành.
8. Ở cuối trang, tải artifact **AutoWiFi-IPA**.
9. Giải nén artifact để lấy `AutoWiFi-unsigned.ipa`.

## Quan trọng: IPA này chưa được ký

GitHub Actions có thể dùng máy macOS để biên dịch iOS, nhưng để cài app lên iPhone thật, app phải được Apple ký bằng provisioning/certificate phù hợp. Workflow này cố ý build **unsigned IPA** để bạn có thể tải file về và ký bằng công cụ sideload trên Windows.

Ví dụ quy trình:

Windows → GitHub Actions → `AutoWiFi-unsigned.ipa` → công cụ ký/sideload → iPhone.

Nếu muốn GitHub tự xuất IPA đã ký, bạn phải cung cấp Apple Developer signing credentials (certificate + provisioning profile hoặc cơ chế ký tương ứng) dưới dạng GitHub Secrets. Không nên đưa certificate/private key trực tiếp vào repository.

## Cách upload nhanh

Bạn có thể kéo thả toàn bộ các file/thư mục vào trang repository trên GitHub. Đảm bảo thư mục `.github/workflows/build-ipa.yml` được giữ nguyên.

## Yêu cầu

- Repository có file `AutoWiFi/AutoWiFi.xcodeproj`
- Workflow dùng GitHub-hosted macOS runner.
- Workflow chỉ chạy khi bạn bấm **Run workflow**.
