import Foundation
import SwiftUI
import PhotosUI

struct CreateNewUserView: View {
    @State var selectedItem = [PhotosPickerItem]()
    @State var selectedImage:[Image]?
    @State var imageData: Data?
    @State var newEmail: String = ""
    @State var newUsername: String = ""
    @State var newPassword: String = ""
    @State var responseMessage: String = ""
    @State var showResponse: Bool = false
    
    func validateUserInput() {
        //None of the fields must be empty
        if !isValidTextEntry(newEmail)    ||
           !isValidTextEntry(newUsername) ||
           !isValidTextEntry(newPassword) {
            responseMessage = "Error: Please fill in all prompts"
            showResponse = true
        } else {
            AuthService.authservice.registerUser(
                username: newUsername,
                email: newEmail,
                password: newPassword,
                imageData: imageData,
                completion: handleUserCreationResponse
            )
        }
    }
    
    func handleUserCreationResponse(response: Bool, error: Error?) {
        if !response && error == nil {
            responseMessage = "Error: nil user response"
        } else if !response {
            responseMessage = error!.localizedDescription
        } else {
            responseMessage = "User successfully created!"
        }
        showResponse = true
    }
    
    var body: some View {
        VStack {
            Text("Create new user")
            if selectedImage != nil {
                ProfileImageView(image: selectedImage![0])
            } else {
                ProfileImageView(image: Image(systemName: "person.crop.circle"))
            }
            
                
            PhotosPicker("Upload profile picture", selection: $selectedItem, maxSelectionCount: 1)
            TextField("Email", text: $newEmail)
            TextField("Username", text: $newUsername)
            SecureField("Password", text: $newPassword)
            
            Button("Create Account") {
                validateUserInput()
            }
            
            if showResponse {
                Text(responseMessage)
            }
        }
        .onChange(of: selectedItem) { _ in
            Task {
                showResponse = false
                if let data = try? await selectedItem[0].loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data),
                       let compressed = uiImage.jpegData(compressionQuality: 0.25)
                    {
                        let image = Image(uiImage: uiImage)
                        selectedImage = [image]
                        imageData = compressed
                    } else {
                        showResponse = true
                        responseMessage = "Error uploading pfp"
                    }
                }
            }
        }
    }
    
    
}

struct CreateUserView_Previews: PreviewProvider {
    static var previews: some View {
        CreateNewUserView()
    }
}
