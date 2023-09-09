import Foundation
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class AuthService {
    
    public static let authservice = AuthService()
    
    public func userSignedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }
    
    public func getCurrentUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }
    
    public func registerUser(username: String, email: String, password: String,
                             imageData: Data?,
                             completion: @escaping (Bool, Error?) -> Void) {
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            guard error == nil else {
                completion(false, error)
                return
            }
            
            guard let newUser = result?.user else {
                completion(false, nil)
                return
            }
            
            //Success: adding display name
            let screenNameRequest = newUser.createProfileChangeRequest()
            screenNameRequest.displayName = username
            screenNameRequest.commitChanges() { error in
                if error != nil {
                    print(error!.localizedDescription)
                }
            }
            
            if imageData != nil {
                let imageData = imageData!
                //Upload pfp to database
                let storageRef = Storage.storage().reference()
                let pfpRef = storageRef.child("images/\(newUser.uid)/profile")
                
                pfpRef.putData(imageData as Data, metadata: nil) { (metadata, error) in
                    guard let _ = metadata else {
                        print(error!.localizedDescription)
                        return
                    }
                }
            }
            
            
            //Adding new user to database
            let rootRef = Database.database().reference()
            let usersRef = rootRef.child("users")
            let newUserRef = usersRef.child(newUser.uid)
            
            newUserRef.setValue(["username" : username, "email" : email]) { error, reference in
                guard error == nil else {
                    completion(false, error)
                    return
                }
                completion(true, nil)
            }
        }
    }
    
    public func userSignIn(email: String, password: String,
                           completion: @escaping (Bool, Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            guard error == nil else {
                completion(false, error)
                return
            }
            completion(true, nil)
        }
    }
    
    public func userSignOut(completion: @escaping (Bool, Error?) -> Void) {
        do {
            try Auth.auth().signOut()
                completion(true, nil)
        } catch {
            completion(false, error)
        }
    }

    //User likes a recipe
    public func userLikeRecipe(_ recipeID: String) {
        guard let user = Auth.auth().currentUser else {
            return
        }
        let userID = user.uid
        let rootRef = Database.database().reference()
        let recipesRef = rootRef.child("recipes")
        let recipeIDRef = recipesRef.child(recipeID)
        let likesRef = recipeIDRef.child("likes")
        likesRef.child(userID).setValue(1, withCompletionBlock: { error, _ in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
        })
    }
    
    //User unlikes a recipe
    public func userUnlikeRecipe(_ recipeID: String) {
        guard let user = Auth.auth().currentUser else {
            return
        }
        let userID = user.uid
        let rootRef = Database.database().reference()
        let recipesRef = rootRef.child("recipes")
        let recipeIDRef = recipesRef.child(recipeID)
        let likesRef = recipeIDRef.child("likes")
        likesRef.child(userID).removeValue(completionBlock: { error, _ in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
        })
    }
    
    //Checks to see if the current logged in user liked a recipe given an ID
    public func userLikedRecipe(_ recipeID: String, completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("Error in userLikedRecipe: User auth failed")
            completion(false)
            return
        }
        let userID = user.uid
        
        let rootRef = Database.database().reference()
        let recipesRef = rootRef.child("recipes")
        let recipeRef = recipesRef.child("\(recipeID)")
        let likesRef = recipeRef.child("likes")
        
        likesRef.observeSingleEvent(of: .value) { snapshot in
            if let likes = snapshot.value as? [String:Int] {
                let keys = likes.keys
                let userLikedRecipe: Bool = keys.contains(userID)
                completion(userLikedRecipe)
            } else {
                print("Error in userLikedRecipe: likesDict could not be parsed as dictionary")
                completion(false)
            }
        }
    }
    
    //User bookmarks a recipe
    public func userBookmarkRecipe(_ recipeID: String, completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            return
        }
        let userID = user.uid
        let rootRef = Database.database().reference()
        
        //Append recipe id to user info for easy retrieval
        let userRef = rootRef.child("users")
        let userIDRef = userRef.child(userID)
        let bookmarked = userIDRef.child("bookmarked")
        
        bookmarked.child(recipeID).setValue(1, withCompletionBlock: { error, _ in
            guard error == nil else {
                print(error!.localizedDescription)
                completion(false)
                return
            }
        })
        
        //Increase bookmark count for recipe post
        let recipesRef = rootRef.child("recipes")
        let recipeIDRef = recipesRef.child(recipeID)
        let bookmarksRef = recipeIDRef.child("bookmarks")
        bookmarksRef.setValue(ServerValue.increment(1))
        
        //succesfully bookmarked
        completion(true)
    }
    
    public func userUnbookmarkRecipe(_ recipeID: String, completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            print("Error: Could not get current user")
            completion(false)
            return
        }
        let userID = user.uid
        let rootRef = Database.database().reference()
        
        //Remove recipe id from user acc
        let usersRef = rootRef.child("users")
        let userIDRef = usersRef.child(userID)
        let bookmarked = userIDRef.child("bookmarked")
        
        bookmarked.child(recipeID).removeValue()
        
        //Decrement bookmark count
        let recipesRef = rootRef.child("recipes")
        let recipeIDRef = recipesRef.child(recipeID)
        let bookmarksRef = recipeIDRef.child("bookmarks")
        bookmarksRef.setValue(ServerValue.increment(-1))
        //success
        completion(true)
    }
    
    
    //Check to see if the current user bookmarked a recipe
    public func userBookmarkedRecipe(_ recipeID: String, completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false)
            return
        }
        let userID = user.uid
        let rootRef = Database.database().reference()
        let userRef = rootRef.child("users")
        let userIDRef = userRef.child(userID)
        let bookmarked = userIDRef.child("bookmarked")
        
        bookmarked.getData() { error, snapshot in
            guard error == nil else {
                completion(false)
                return
            }
            if let bookmarkedDict = snapshot!.value as? [String:Any] {
                let bookmarkedKeys = bookmarkedDict.keys
                let userBookmarkedRecipe: Bool = bookmarkedKeys.contains(recipeID)
                completion(userBookmarkedRecipe)
                return
            } else {
                completion(false)
            }
        }
    }
    
    public func userMakeComment(recipeID: String?, contents: String,
                                completion: @escaping (Bool, Error?, Comment?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false, nil, nil)
            return
        }
        
        guard let recipeID = recipeID else {
            print("Error: No recipe id found")
            completion(false, nil, nil)
            return
        }

        let userID = user.uid
        let rootRef = Database.database().reference()
        let recipesRef = rootRef.child("recipes")
        let recipeIDRef = recipesRef.child(recipeID)
        let commentsRef = recipeIDRef.child("comments")
        let newCommentRef = commentsRef.childByAutoId()

        guard let commentID: String = newCommentRef.key else {
            print("Error in userMakeComment: Comment ID could not be created")
            completion(false, nil, nil)
            return
        }

        let commentObj: Comment = Comment(id: commentID,
                                          user: userID,
                                          datetime: Date.now.formatted(),
                                          content: contents)

        guard let commentVal: NSDictionary = commentObj.dict else {
            print("Error in userMakeComment: Could not parse commentObj as NSDictionary")
            completion(false, nil, nil)
            return
        }
        
        newCommentRef.setValue(commentVal, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false, error, nil)
                return
            }
            completion(true, nil, commentObj) //returns response, error, and contents of comment
        })
    }
    
    //called when the current user has followed another user
    public func userFollowed(otherUserID: String, completion: @escaping (Bool, String) -> Void) {
        checkIfFollowing(otherUserID: otherUserID) { response, message in
            if response == false {
                //current user does not follow other user
                guard let user = Auth.auth().currentUser else { return }
                let userID = user.uid //current user id
                let rootRef = Database.database().reference()
                let userRef = rootRef.child("users/\(userID)") //ref of current user
                let otherUserRef = rootRef.child("users/\(otherUserID)")
                
                userRef.child("follows/\(otherUserID)").getData() { error, snapshot in
                    DispatchQueue.main.async {
                        //update followers list for other user
                        otherUserRef.child("followers").child("\(userID)").setValue(1, withCompletionBlock: { error, _ in
                            guard error == nil else {
                                completion(false, error!.localizedDescription)
                                return
                            }
                        })
                        //update following list for current user
                        userRef.child("follows").child(otherUserID).setValue(1, withCompletionBlock: { error, _ in
                            guard error == nil else {
                                completion(false, error!.localizedDescription)
                                return
                            }
                        })
                        completion(true, "User followed") //success
                    }
                }
            }
            else {
                completion(false, "Error: current user is already following this user")
            }
        }
            
    }
    
    public func userUnfollowed(otherUserID: String, completion: @escaping (Bool, String) -> Void) {
        checkIfFollowing(otherUserID: otherUserID) { response, message in
            
            if response == true {
                guard let user = Auth.auth().currentUser else { return }
                let userID = user.uid //current user id
                let rootRef = Database.database().reference()
                let userRef = rootRef.child("users/\(userID)") //ref of current user
                let otherUserRef = rootRef.child("users/\(otherUserID)")
                
                userRef.child("follows/\(otherUserID)").getData() { error, snapshot in
                    DispatchQueue.main.async {
                        if let _ = snapshot {
                            //update followers list for other user
                            otherUserRef.child("followers").child("\(userID)").removeValue() {error, dbRef in
                                if let error = error {
                                    completion(false, error.localizedDescription)
                                }
                            }
                            //update following list for current user
                            userRef.child("follows").child(otherUserID).removeValue() {error, dbRef in
                                if let error = error {
                                    completion(false, error.localizedDescription)
                                }
                            }
                            completion(true, "Successfully unfollowed")
                        
                        }
                        else {
                            completion(false, error!.localizedDescription)
                        }
                        
                    }
                }
                
            }
            else {
                completion(false, "Cannot unfollow because current user does not follow this user")
            }
        }
    }
    
    //checks if the current user is following another user
    public func checkIfFollowing(otherUserID: String, completion: @escaping (Bool, String) -> Void) {
        guard let user = Auth.auth().currentUser else { return }
        let userID = user.uid //current user id
        let rootRef = Database.database().reference()
        let userRef = rootRef.child("users/\(userID)") //ref of current user
        
        userRef.child("follows/\(otherUserID)").getData() { error, snapshot in
            DispatchQueue.main.async {
                if let snapshot = snapshot {
                    if snapshot.exists() { //check if current user is already following other user
                        completion(true, "Current user is following this user")
                    }
                    else {
                        completion(false, "Current user is not following this user")
                    }
                }
            }
        }
    }
    
    //get the list of ID's for the followers of any user
    public func getFollowersIDs(userID: String, completion: @escaping (Bool, [String]) -> Void) {
        let rootRef = Database.database().reference()
        let userFollowersRef = rootRef.child("users/\(userID)/followers")
        
        //find follower's ids
        userFollowersRef.getData() { error, snapshot in
            DispatchQueue.main.async {
                if let error = error {
                    print(error.localizedDescription)
                    completion(false, [])
                    return
                }
                var followers: [String] = [] //stores userID's of followers
                for child in snapshot!.children {
                    if let entry = child as? DataSnapshot {
                        followers.append(entry.key as String)
                    }
                    else {
                        print("Error getting followers")
                        completion(false, [])
                    }
                }
                completion(true, followers)
            }
        }
        
    }
    //find list of id's that userID follows
    public func getFollowingIDs(userID: String, completion: @escaping (Bool, [String]) -> Void) {
        let root = Database.database().reference()
        let followingRef = root.child("users/\(userID)/follows")
        
        followingRef.getData() { error, snapshot in
            DispatchQueue.main.async {
                if let error = error {
                    print(error.localizedDescription)
                    completion(false, [])
                    return
                }
                var followingList: [String] = [] //stores id's of users that userID follows
                for child in snapshot!.children {
                    if let entry = child as? DataSnapshot {
                        followingList.append(entry.key as String)
                    }
                    else {
                        print("Error getting followers")
                        completion(false, [])
                    }
                }
                completion(true, followingList)
            }
        }
    }
    
    public func getUploadedIDs(userID: String, completion: @escaping (Bool, [String]) -> Void) {
        let root = Database.database().reference()
        let uploadedRef = root.child("users/\(userID)/uploaded")
        
        uploadedRef.observeSingleEvent(of: .value) { snapshot, error in
            if let uploaded = snapshot.value as? [String:Any] {
                completion(true, Array(uploaded.keys))
            } else {
                print("Error in getUploadedIDs: Could not parse snapshot value correctly")
                completion(false, [])
            }
        }
    }
    
    //Return a list of recipe entry structs uploaded by a user
    public func getUploadedRecipeEntries(userID: String, completion: @escaping (Bool, [RecipeEntry]) -> Void) {
        getUploadedIDs(userID: userID) { response, uploadedIDs in
            if !response {
                print("Error in getUploadedIDs")
                completion(false, [])
            } else {
                let recipesRef = Database.database().reference().child("recipes")
                var uploadedEntries: [RecipeEntry] = []
                let taskHandler = DispatchGroup()
                
                for recipeID in uploadedIDs {
                    let recipeIDRef = recipesRef.child(recipeID)
                    taskHandler.enter()
                    recipeIDRef.observeSingleEvent(of: .value) { snapshot in
                        guard let dict = snapshot.value as? NSDictionary else {
                            print("Error in getUploadedRecipeEntries: Cannot parse snapshot as NSDictionary")
                            completion(false, [])
                            return
                        }
                        guard let re = RecipeEntry.fromDict(dict) else {
                            print("Error in getUploadedRecipeEntries: FromDict call failed")
                            completion(false, [])
                            return
                        }
                        uploadedEntries.append(re)
                        taskHandler.leave()
                    }
                }
                
                taskHandler.notify(queue: .main) {
                    completion(true, uploadedEntries)
                }
            }
        }
    }
    
    //ID-Name map for followers of a userid
    public func getFollowersMap(userID: String, completion: @escaping (Bool, [String:String], String) -> Void) {
        getFollowersIDs(userID: userID) { response, followerIDs in
            if response == true {
                self.getIDsUsernamesMap(userIDs: followerIDs, completion: completion)
            } else {
                completion(false, [:], "getFollowersIDs failed")
            }
        }
    }
    
    //ID-Name map for following of a userid
    public func getFollowingMap(userID: String, completion: @escaping (Bool, [String:String], String) -> Void) {
        getFollowingIDs(userID: userID) { response, followingIDs in
            if response == true {
                self.getIDsUsernamesMap(userIDs: followingIDs, completion: completion)
            } else {
                completion(false, [:], "getFollowingIDs failed")
            }
        }
    }
    
    //Returns a map for a collection of userIDs
    public func getIDsUsernamesMap(userIDs: [String], completion: @escaping (Bool, [String:String], String) -> Void) {
        let usersRef = Database.database().reference().child("users")
        var usernames: [String:String] = [:]
        // we need this since we are waiting for multiple asyc tasks to finish before returning completion handler
        let taskHandler = DispatchGroup()
        
        for id in userIDs {
            let userIDRef = usersRef.child(id)
            taskHandler.enter() //signaling start of new async task
            userIDRef.observeSingleEvent(of: .value) { snapshot in
                guard let dict = snapshot.value as? [String: Any] else {
                    completion(false, [:], "could not read from snapshot")
                    return
                }
                guard let username = dict["username"] as? String else {
                    completion(false, [:], "could not retrieve username")
                    return
                }
                usernames[id] = username
                taskHandler.leave() //signaling completion of async task
            }
            
        }
        
        taskHandler.notify(queue: .main) {
            //return once all async tasks are done
            completion(true, usernames, "retrieved usernames")
        }
    }
}

