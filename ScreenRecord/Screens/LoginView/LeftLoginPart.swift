//
//  LeftLoginPart.swift
//  ScreenRecord
//
//  Created by Raman Tank on 05/02/25.
//

import SwiftUI

struct LeftLoginPart: View {
    @State private var email: String = ""
    @State private var password: String = ""
    var body: some View {
        VStack(
            alignment: .center,
            spacing: 10 ) {
            HStack(spacing: 0) {
                        Text("Screen")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Record")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
         
                    Text("Welcome back, login to continue.")
                        .foregroundColor(.secondary)

                HStack(spacing: 40) {
                        Divider().foregroundColor(.secondary)
                            .rotationEffect(
                                .degrees(90)
                            )
                        Text("OR")
                            .foregroundColor(.secondary)
                        Divider().foregroundColor(.secondary)
                        .rotationEffect(
                                .degrees(90)
                            )
                    }
                    .padding(.vertical, 8)

                    // MARK: - Email & Password Fields
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        TextField("Enter your email address", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                          
                        
                        Text("Password")
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        SecureField("Input your password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    // MARK: - Login Button
                    Button(action: {
                        // Login action here
                    }) {
                        Text("Login Account")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .cornerRadius(8)
                    }
                    .padding(.top, 16)

                    // MARK: - Sign-up Link
                    HStack {
                        Text("Don’t have an account?")
                            .foregroundColor(.secondary)
                        Button("Sign-up") {
                            // Sign-up action here
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.bottom, 20)

                    Spacer()
                }
                .padding(.horizontal, 24)
                
            }
}

#Preview {
    LeftLoginPart()
}
