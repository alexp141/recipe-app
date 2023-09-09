import Foundation
import SwiftUI

struct UserLoginView: View {
    @EnvironmentObject var recipes: RecipeObserver
    @EnvironmentObject var userInfo: UserInformation
    
    @State var loginEmail: String = ""
    @State var loginPassword: String = ""
    @State var showResponse: Bool = false
    @State var responseMessage: String = ""
    
    @Binding var userLoggedIn: Bool
    
    func validateUserInput() {
        //None of the fields must be empty
        if !isValidTextEntry(loginEmail)    ||
           !isValidTextEntry(loginPassword) {
            responseMessage = "Error: Please fill in all prompts"
            showResponse = true
        } else {
            AuthService.authservice.userSignIn(
                email: loginEmail,
                password: loginPassword,
                completion: handleUserSignInResponse)
        }
    }
    
    func handleUserSignInResponse(response: Bool, error: Error?) {
        if !response && error == nil {
            responseMessage = "Error: nil user response"
            showResponse = true
        } else if !response {
            responseMessage = error!.localizedDescription
            showResponse = true
        } else {
            //Change view context and launch observer
            userInfo.updateLocalUserData()
            userLoggedIn = true
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Email", text: $loginEmail)
                SecureField("Password", text: $loginPassword)
                
                Button("Sign In") {
                    validateUserInput()
                }
                
                NavigationLink("Create Account") {
                    CreateNewUserView()
                }
                
                if showResponse {
                    Text(responseMessage)
                }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        UserLoginView(userLoggedIn: .constant(false))
    }
}
