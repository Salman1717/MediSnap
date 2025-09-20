//
//  AuthDataResultModel.swift
//  MediSnap
//
//  Created by Salman Mhaskar on 20/09/25.
//

import FirebaseAuth


struct AuthDataResultModel {
    let uid: String
    let email: String?
    let photoUrl: String?
    
    init(user: User) {
        self.uid = user.uid
        self.email = user.email
        self.photoUrl = user.photoURL?.absoluteString
    }
}
