//
//  ViewModel.swift
//  ScreenRecord
//
//  Created by Raman Tank on 05/02/25.
//

import Foundation

class ViewModel : ObservableObject{
    @Published var email: String = ""
    @Published var password: String = ""
}
