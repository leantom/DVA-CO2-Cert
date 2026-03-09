//
//  ViewController.swift
//  DVA-C02-Cognito
//
//  Created by QuangHo on 2/3/26.
//

import UIKit

class ViewController: UIViewController {
    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let confirmationCodeField = UITextField()
    private let signUpButton = UIButton(type: .system)
    private let confirmButton = UIButton(type: .system)
    private let signInButton = UIButton(type: .system)
    private let statusTextView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cognito User Pools"
        view.backgroundColor = .systemBackground
        configureUI()
        appendStatus("Ready. Fill email/password and call Cognito actions.")
        appendStatus("If requests fail immediately, set Cognito values in Info.plist first.")
    }

    @objc private func signUpTapped() {
        guard let request = buildRequestPayload(includePassword: true) else { return }

        performCognitoRequest(
            target: "AWSCognitoIdentityProviderService.SignUp",
            payload: [
                "ClientId": request.clientId,
                "Username": request.username,
                "Password": request.password,
                "UserAttributes": [
                    ["Name": "email", "Value": request.username]
                ]
            ]
        ) { [weak self] result in
            switch result {
            case .success(let json):
                let isConfirmed = (json["UserConfirmed"] as? Bool) == true
                if isConfirmed {
                    self?.appendStatus("Sign up complete: user already confirmed.")
                } else {
                    self?.appendStatus("Sign up successful. Check email/SMS for confirmation code.")
                }
            case .failure(let error):
                self?.appendStatus("Sign up failed: \(error.localizedDescription)")
            }
        }
    }

    @objc private func confirmTapped() {
        guard let clientId = loadClientId() else { return }
        guard let email = normalizedText(emailField), !email.isEmpty else {
            appendStatus("Email is required.")
            return
        }
        guard let code = normalizedText(confirmationCodeField), !code.isEmpty else {
            appendStatus("Confirmation code is required.")
            return
        }

        performCognitoRequest(
            target: "AWSCognitoIdentityProviderService.ConfirmSignUp",
            payload: [
                "ClientId": clientId,
                "Username": email,
                "ConfirmationCode": code
            ]
        ) { [weak self] result in
            switch result {
            case .success:
                self?.appendStatus("Confirmation succeeded. You can now sign in.")
            case .failure(let error):
                self?.appendStatus("Confirmation failed: \(error.localizedDescription)")
            }
        }
    }

    @objc private func signInTapped() {
        guard let request = buildRequestPayload(includePassword: true) else { return }

        performCognitoRequest(
            target: "AWSCognitoIdentityProviderService.InitiateAuth",
            payload: [
                "AuthFlow": "USER_PASSWORD_AUTH",
                "ClientId": request.clientId,
                "AuthParameters": [
                    "USERNAME": request.username,
                    "PASSWORD": request.password
                ]
            ]
        ) { [weak self] result in
            switch result {
            case .success(let json):
                guard let auth = json["AuthenticationResult"] as? [String: Any] else {
                    self?.appendStatus("Sign in failed: no AuthenticationResult in response.")
                    return
                }
                let expiresIn = auth["ExpiresIn"] as? Int ?? 0
                let hasRefreshToken = (auth["RefreshToken"] as? String)?.isEmpty == false
                self?.appendStatus("Sign in successful. Expires in \(expiresIn)s. Refresh token returned: \(hasRefreshToken).")
            case .failure(let error):
                self?.appendStatus("Sign in failed: \(error.localizedDescription)")
            }
        }
    }

    private func configureUI() {
        emailField.placeholder = "Email / Username"
        emailField.borderStyle = .roundedRect
        emailField.autocapitalizationType = .none
        emailField.autocorrectionType = .no
        emailField.keyboardType = .emailAddress

        passwordField.placeholder = "Password"
        passwordField.borderStyle = .roundedRect
        passwordField.isSecureTextEntry = true

        confirmationCodeField.placeholder = "Confirmation Code"
        confirmationCodeField.borderStyle = .roundedRect
        confirmationCodeField.keyboardType = .numberPad

        signUpButton.setTitle("Sign Up", for: .normal)
        confirmButton.setTitle("Confirm Sign Up", for: .normal)
        signInButton.setTitle("Sign In", for: .normal)

        signUpButton.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)

        statusTextView.isEditable = false
        statusTextView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        statusTextView.layer.borderColor = UIColor.systemGray4.cgColor
        statusTextView.layer.borderWidth = 1
        statusTextView.layer.cornerRadius = 8
        statusTextView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)

        let stack = UIStackView(arrangedSubviews: [
            emailField,
            passwordField,
            confirmationCodeField,
            signUpButton,
            confirmButton,
            signInButton,
            statusTextView
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            statusTextView.heightAnchor.constraint(equalToConstant: 220)
        ])
    }

    private func buildRequestPayload(includePassword: Bool) -> (clientId: String, username: String, password: String)? {
        guard let clientId = loadClientId() else { return nil }
        guard let username = normalizedText(emailField), !username.isEmpty else {
            appendStatus("Email/username is required.")
            return nil
        }

        let password = normalizedText(passwordField) ?? ""
        if includePassword && password.isEmpty {
            appendStatus("Password is required.")
            return nil
        }

        return (clientId, username, password)
    }

    private func normalizedText(_ field: UITextField) -> String? {
        field.text?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func loadClientId() -> String? {
        guard let clientId = Bundle.main.object(forInfoDictionaryKey: "CognitoClientId") as? String,
              !clientId.isEmpty,
              clientId != "YOUR_COGNITO_APP_CLIENT_ID" else {
            appendStatus("Missing CognitoClientId in Info.plist.")
            return nil
        }
        return clientId
    }

    private func loadRegion() -> String? {
        guard let region = Bundle.main.object(forInfoDictionaryKey: "CognitoRegion") as? String,
              !region.isEmpty else {
            appendStatus("Missing CognitoRegion in Info.plist.")
            return nil
        }
        return region
    }

    private func performCognitoRequest(
        target: String,
        payload: [String: Any],
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        guard let region = loadRegion() else { return }

        guard let url = URL(string: "https://cognito-idp.\(region).amazonaws.com/") else {
            appendStatus("Invalid Cognito URL for region \(region).")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-amz-json-1.1", forHTTPHeaderField: "Content-Type")
        request.setValue(target, forHTTPHeaderField: "X-Amz-Target")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            appendStatus("JSON encoding failed: \(error.localizedDescription)")
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(CognitoRequestError.invalidResponse("Missing HTTP response.")))
                }
                return
            }

            guard let data else {
                DispatchQueue.main.async {
                    completion(.failure(CognitoRequestError.invalidResponse("Missing response body.")))
                }
                return
            }

            let parsedJSON = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any]
            if (200...299).contains(httpResponse.statusCode) {
                DispatchQueue.main.async {
                    completion(.success(parsedJSON ?? [:]))
                }
                return
            }

            let serviceMessage = self?.extractServiceError(from: parsedJSON) ?? "HTTP \(httpResponse.statusCode)"
            DispatchQueue.main.async {
                completion(.failure(CognitoRequestError.serviceError(serviceMessage)))
            }
        }.resume()
    }

    private func extractServiceError(from json: [String: Any]?) -> String {
        guard let json else { return "Cognito service returned an unknown error." }
        let type = (json["__type"] as? String) ?? (json["code"] as? String) ?? "Error"
        let message = (json["message"] as? String) ?? (json["Message"] as? String) ?? "No details."
        return "\(type): \(message)"
    }

    private func appendStatus(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let line = "[\(formatter.string(from: Date()))] \(message)\n"

        DispatchQueue.main.async {
            self.statusTextView.text.append(line)
            guard self.statusTextView.text.count > 0 else { return }
            let range = NSRange(location: self.statusTextView.text.count - 1, length: 1)
            self.statusTextView.scrollRangeToVisible(range)
        }
    }
}

private enum CognitoRequestError: LocalizedError {
    case invalidResponse(String)
    case serviceError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse(let message):
            return message
        case .serviceError(let message):
            return message
        }
    }
}
