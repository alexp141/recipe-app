import Foundation
import FirebaseDatabase
import FirebaseAuth

//Local storage
//USE FOR DISPLAY ONLY
class UserInformation : ObservableObject {
    var userName: String?
    var email: String?
    var uid: String?
    
    init() {
        updateLocalUserData()
    }
    
    public func updateLocalUserData() {
        guard let user = Auth.auth().currentUser else { return }
        self.userName = user.displayName
        self.email = user.email
        self.uid = user.uid
    }
}
