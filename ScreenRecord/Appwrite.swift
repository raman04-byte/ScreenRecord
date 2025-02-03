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
    var client: Client
    var account: Account
    
    public init(){
        self.client = Client().setEndpoint("https://cloud.appwrite.io/v1").setProject("record")
        
        self.account = Account(client)
    }
}
