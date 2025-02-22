//
//  Appwrite.swift
//  ScreenRecord
//
//  Created by Raman Tank on 01/02/25.
//

import Foundation
import Appwrite
import JSONCodable

class Appwrite
{
    static let share = Appwrite()
    var client: Client
    var account: Account
    var currentUserId: String?
    
    public init(){
        self.client = Client().setEndpoint("https://cloud.appwrite.io/v1").setProject("record")
        self.account = Account(client)
    }
    
    public func onRegister(
        _ email: String,
        _ password: String
    ) async -> Bool {
        let newUserID = ID.unique()
        
        do{
            let _ = try await account.create(
                userId: newUserID, email: email, password: password
            )
            print(newUserID)
            self.currentUserId = newUserID
            return true
        }catch{
            print("Error \(error.localizedDescription)")
            return false
        }
    }
    
    public func onLogin(
        _ email: String,
        _ password: String
    ) async -> Bool {
        guard let userId = currentUserId else {
            print("Not able to found the userID")
            return false
        }
        print(userId)
        do{
            let session = try await account.createEmailPasswordSession(email: email, password: password)
            print("Session with \(session.userId) is created successfully on Appwrite console")
            return true
        } catch {
            print("Error \(error.localizedDescription)")
            return false
        }
    }
    
    public func onLogout() async throws {
        _ = try await account.deleteSession(sessionId: "current")
    }
    
}
