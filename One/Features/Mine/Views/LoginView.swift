import SwiftUI

/// 手机号 + 短信验证码登录。
struct LoginView: View {
    @Bindable private var auth = AuthSession.shared

    @State private var mobile = ""
    @State private var code = ""
    @FocusState private var focusedField: Field?

    private let areaCode = "86"
    /// 与官网 `img_me_visitor_bg` 比例接近（1125×978 取顶图区域）。
    private let backgroundImageHeight: CGFloat = 300

    private enum Field {
        case mobile, code
    }

    var body: some View {
        VStack(spacing: 0) {
            loginImageBar

            ScrollView {
                VStack(spacing: 28) {
                    formCard
                    loginButton
                    Text("未注册的手机号验证后将自动创建账号")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        }
        .ignoresSafeArea(edges: .top)
        .onTapGesture { focusedField = nil }
    }

    private var loginImageBar: some View {
        Image("LoginBackground")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: backgroundImageHeight)
            .clipped()
            .accessibilityHidden(true)
    }

    private var formCard: some View {
        VStack(spacing: 14) {
            phoneRow
            codeRow

            if let error = auth.errorMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(error)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.footnote)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }

    private var phoneRow: some View {
        HStack(spacing: 0) {
            Text("+\(areaCode)")
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .frame(height: 48)

            Divider()
                .frame(height: 24)

            TextField("请输入手机号", text: $mobile)
                .keyboardType(.numberPad)
                .textContentType(.telephoneNumber)
                .focused($focusedField, equals: .mobile)
                .padding(.horizontal, 12)
                .frame(height: 48)
                .onChange(of: mobile) { _, value in
                    mobile = String(value.filter(\.isNumber).prefix(11))
                }
        }
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var codeRow: some View {
        HStack(spacing: 10) {
            TextField("请输入验证码", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focusedField, equals: .code)
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onChange(of: code) { _, value in
                    code = String(value.filter(\.isNumber).prefix(8))
                }

            Button {
                focusedField = nil
                Task { await auth.sendSMS(mobile: mobile, area: areaCode) }
            } label: {
                Text(smsButtonTitle)
                    .font(.caption2.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .controlSize(.mini)
            .disabled(!canSendSMS)
        }
    }

    private var loginButton: some View {
        Button {
            focusedField = nil
            Task { await auth.login(mobile: mobile, code: code, area: areaCode) }
        } label: {
            Group {
                if auth.isLoggingIn {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("登录")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .frame(maxWidth: 220)
            .frame(height: 36)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .frame(maxWidth: .infinity)
        .disabled(!canLogin)
    }

    private var canSendSMS: Bool {
        !auth.isSendingSMS && auth.smsCooldown == 0 && mobile.count == 11
    }

    private var canLogin: Bool {
        !auth.isLoggingIn && mobile.count == 11 && code.count >= 4
    }

    private var smsButtonTitle: String {
        if auth.isSendingSMS { return "发送中" }
        if auth.smsCooldown > 0 { return "\(auth.smsCooldown)s" }
        return "获取验证码"
    }
}

#Preview {
    LoginView()
}