import Foundation
import FirebaseDatabase
import FirebaseStorage

//We do not want a string that is just whitespace
//for any user prompts
func isValidTextEntry(_ str: String) -> Bool {
    return !str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
}

//Given a userID, we can return the user's display name
func getDisplayName(_ userID: String, completion: @escaping (Bool, String?, Error?) -> Void) {
    let rootRef = Database.database().reference()
    let usersRef = rootRef.child("users")
    let userIDRef = usersRef.child(userID)
    
    DispatchQueue.main.async {
        userIDRef.child("username").getData { error, snapshot in
            if error != nil {
                print(error!.localizedDescription)
                completion(false, nil, error)
                return
            }
            
            guard let displayName = snapshot!.value as? String else {
                completion(false, nil, nil)
                return
            }
            
            completion(true, displayName, nil)
        }
    }
}

//Given a userID, we can return the user's profile picture
func getProfilePicture(userID: String, completion: @escaping (Bool, Data?, Error?) -> Void) {
    let storage = Storage.storage().reference()
    let profile = storage.child("images/\(userID)/profile")
    DispatchQueue.main.async {
        profile.getData(maxSize: 1 * 2048 * 2048) { data, error in
            if let error = error {
                print("Error getting image url")
                completion(false, nil, error)
            } else {
                completion(true, data, nil)
            }
        }
    }
}
