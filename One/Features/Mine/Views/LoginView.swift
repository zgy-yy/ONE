import SwiftUI

/// 手机号 + 短信验证码登录。
struct LoginView: View {
    @Bindable private var auth = AuthSession.shared

    @State private var mobile = ""
    @State private var code = ""
    @FocusState private var focusedField: Field?

    private let areaCode = "86"

    private enum Field {
        case mobile, code
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                header
                formCard
                loginButton
                Text("未注册的手机号验证后将自动创建账号")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .padding(.top, 36)
            .padding(.bottom, 24)
        }
        .tracksSearchFABScroll()
        .scrollDismissesKeyboard(.interactively)
        .background(pageBackground)
        .onTapGesture { focusedField = nil }
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.accentColor)
            }

            Text("欢迎回来")
                .font(.title.weight(.bold))

            Text("使用手机号验证码登录 One")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
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
                    .font(.caption.weight(.semibold))
                    .frame(minWidth: 76, minHeight: 34)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
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

    private var pageBackground: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color.accentColor.opacity(0.06),
                Color(.systemGroupedBackground),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
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
