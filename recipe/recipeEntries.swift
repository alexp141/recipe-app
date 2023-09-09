import Foundation
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

struct RecipeEntry: Codable, Identifiable, Hashable {
    var id: String?
    var name: String
    //user id
    var user: String
    var description: String
    var ingredients: [String]
    var directions: [String]
    //collection of user ids
    var likes: [String:Int]
    var bookmarks: Int
    var datetime: String
    //User id - comment struct
    var comments: [String:Comment]
    
    var dict: NSDictionary? {
        guard let id_str = id else { print("Dict not created: id value not found!"); return nil }
        return NSDictionary(dictionary:
        ["id": id_str,
         "name": name,
         "user": user,
         "description": description,
         "ingredients": ingredients,
         "directions" : directions,
         "likes": likes,
         "bookmarks": bookmarks,
         "datetime": datetime,
         "comments": comments
        ])
    }
    
    static func fromDict(_ d: NSDictionary) -> RecipeEntry? {
        guard let id = d["id"] as? String else { print("Could not parse id from NSDictionary"); return nil }
        guard let name = d["name"] as? String else { print("Could not parse name from NSDictionary"); return nil }
        guard let user = d["user"] as? String else { print("Could not parse user from NSDictionary"); return nil }
        guard let description = d["description"] as? String else { print("Could not parse description from NSDictionary"); return nil }
        guard let ingredients = d["ingredients"] as? [String] else { print("Could not parse ingredients from NSDictionary"); return nil }
        guard let directions = d["directions"] as? [String] else { print("Could not parse directions from NSDictionary"); return nil }
        guard let bookmarks = d["bookmarks"] as? Int else { print("Could not parse bookmark count from NSDictionary"); return nil }
        guard let datetime = d["datetime"] as? String else { print("Could not parse datetime from NSDictionary"); return nil}
        guard let likes = d["likes"] as? [String:Int]? else { print("Could not parse likes from NSDictionary"); return nil }
        guard let comments = d["comments"] as? [String:NSDictionary]? else { print("Could not parse comments as NSDictionary"); return nil }
        
        let commentsMap: [String:Comment] = comments?.mapValues { Comment.fromDict($0)! } ?? [:]
        
        return RecipeEntry(id: id,
                           name: name,
                           user: user,
                           description: description,
                           ingredients: ingredients,
                           directions: directions,
                           likes: likes ?? [:],
                           bookmarks: bookmarks,
                           datetime: datetime,
                           comments: commentsMap
        )
    }
    
    func getLikes() -> Int {
        return likes.count
    }
    
    //Get img async and do callback function when completed
    func getRecipeImg(completion: @escaping (Bool, Data?, Error?) -> Void) {
        let storageRef = Storage.storage().reference()
        let imagesRef = storageRef.child("images")
        let userRef = imagesRef.child(self.user)
        
        guard let recipeID = id else {
            print("Error getting recipe image: Recipe id not found")
            completion(false, nil, nil)
            return
        }
        
        let recipeRef = userRef.child(recipeID)
        let imgRef = recipeRef.child("recipeImage.jpg")
        
        DispatchQueue.main.async {
            imgRef.getData(maxSize: 1 * 2048 * 2048) { data, error in
                if let error = error {
                    print("Error getting image url")
                    completion(false, nil, error)
                } else {
                    completion(true, data, nil)
                }
            }
        }
    }
    
}

//Tracks all recipe entry information stored in the application
class RecipeObserver: ObservableObject {
    private var launched = false
    
    @Published var allRecipes: [String:RecipeEntry] = [:]
    
    //List of recipes that the user views on the home screen
    @Published var homeFeed: [String:RecipeEntry] = [:]
    
    //Realtime list of recipes that will be added to home feed when user refreshes
    private var addHomeFeed: [RecipeEntry] = []
    
    //Realtime set of recipe (ids) that will be removed when the user refreshes
    private var removeHomeFeed: Set<String> = []
    
    //Realtime set of recipes that have been changed in some other way
    //We will update these recipes when the user refreshes
    private var changedHomeFeed: Set<String> = []
    
    //Search results
    @Published var searchFeed: [RecipeEntry] = []
    
    //Saved recipes
    @Published var bookmarkFeed: [RecipeEntry] = []
    
    var bookmarkRemove: [RecipeEntry] = []
    
    init() {
        if AuthService.authservice.userSignedIn() {
            launchObserver()
        } else {
            print("User not signed in: Observer will not launch unless explicity called")
        }
    }
    
    func launchObserver() {
        if launched {
            print("Error launching observer: Observer has already been launched!")
        } else {
            print("Launching observer...")
            launched = true
            getAndObserveHomeFeed()
            getAndObserveBookmarkFeed()
        }
    }
    
    func killObserver() {
        if !launched {
            print("Error killing observer: Observer has not been launched!")
            return
        }
        
        print("Killing Observer")
        launched = false
        
        //Reset observer memory
        self.homeFeed = [:]
        self.addHomeFeed = []
        self.removeHomeFeed = []
        self.changedHomeFeed = []
        self.searchFeed = []
        self.bookmarkFeed = []
        self.bookmarkRemove = []
        
        //Reset all observer handles
        let rootRef = Database.database().reference()
        let recipesRef = rootRef.child("recipes")
        recipesRef.removeAllObservers()
    }
    
    func getAndObserveHomeFeed() {
        let rootRef = Database.database().reference()
        let recipesRef = rootRef.child("recipes")
        
        //Get recipes info
        recipesRef.getData() { error, snapshot in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            DispatchQueue.main.async {
                for recipe in snapshot!.children {
                    guard let recipe_item = recipe as? DataSnapshot else {
                        print("Error: recipe item cannot be cast as DataSnapshot")
                        return
                    }
                    guard let recipe_value = recipe_item.value as? NSDictionary else {
                        print("Error: recipe value cannot be cast as NSDictionary")
                        return
                    }
                    
                    guard let re = RecipeEntry.fromDict(recipe_value) else {
                        print("Error: RecipeEntry cannot be created from recipe value")
                        return
                    }
                    let recipe_id = recipe_item.key
                    AuthService.authservice.checkIfFollowing(otherUserID: re.user) { res, _ in
                        if res ||  re.user == AuthService.authservice.getCurrentUserId() {
                            self.homeFeed[recipe_id] = re
                        }
                    }
                    self.allRecipes[recipe_id] = re
                }
            }
        }
        
        //Observe db
        recipesRef.observe(.childAdded) { snapshot in
            if let v = snapshot.value as? NSDictionary,
               let re = RecipeEntry.fromDict(v) {
                //Will be added to home feed when user refreshes
                AuthService.authservice.checkIfFollowing(otherUserID: re.user) { res, _ in
                    if res || re.user == AuthService.authservice.getCurrentUserId() {
                        self.addHomeFeed.append(re)
                    }
                }
                self.allRecipes[re.id!] = re
            }
        }
        
        recipesRef.observe(.childRemoved) { snapshot in
            //When user refreshes home page, we will know to remove this recipe
            let recipe_id: String = snapshot.key
            self.removeHomeFeed.insert(recipe_id)
            self.allRecipes.removeValue(forKey: recipe_id)
        }
        
        recipesRef.observe(.childChanged) { snapshot in
            //When user refreshes home page, we will know which recipes to update
            let recipe_id: String = snapshot.key
            self.changedHomeFeed.insert(recipe_id)
            if let v = snapshot.value as? NSDictionary,
               let re = RecipeEntry.fromDict(v) {
                self.allRecipes[re.id!] = re
            }
        }
        
    }
    
    func getAndObserveBookmarkFeed() {
        guard let userID: String = AuthService.authservice.getCurrentUserId() else {
            print("Bookmark observer failed to launch: Cannot get current user id from auth service")
            return
        }
        let rootRef = Database.database().reference()
        let recipesRef = rootRef.child("recipes")
        let userRef = rootRef.child("users")
        let userIDRef = userRef.child(userID)
        let bookmarkedRef = userIDRef.child("bookmarked")
        
        //Get bookmark data
        bookmarkedRef.getData() { error, snapshot in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            DispatchQueue.main.async {
                for bookmarkChild in snapshot!.children {
                    print("Bookmark item")
                    guard let bookmarkIDItem = bookmarkChild as? DataSnapshot else {
                        print("Bookmark item could not be cast as data snapshot")
                        return
                    }
                    let bookmarkRecipeID: String = bookmarkIDItem.key
                    let recipeIDRef = recipesRef.child(bookmarkRecipeID)
                    
                    recipeIDRef.getData() { error, snapshot in
                        guard error == nil else {
                            print("Error in getting data from recipeID reference")
                            print(error!.localizedDescription)
                            return
                        }
                        guard let recipeValue = snapshot!.value as? NSDictionary else {
                            print("Bookmarked item could not be parsed as NSDicitonary")
                            return
                        }
                        guard let saved_entry = RecipeEntry.fromDict(recipeValue[bookmarkRecipeID] as! NSDictionary) else {
                            print("Error in bookmark feed retrieval: Recipe entry could not be created from NSDictionary")
                            return
                        }
                        self.bookmarkFeed.append(saved_entry)
                    }
                }
            }
        }
    }
    
    //Use this whenever the user enters the bookmark tab
    func doBookmarkRefresh() {
        for recipe in bookmarkRemove {
            self.bookmarkFeed.removeAll(where: { re in re.id! == recipe.id! })
        }
        bookmarkRemove = []
    }
    
    //Add to addition set all recipes that are uploaded by the user that the logged
    //in user just followed
    func followAdd(userRecipes: [RecipeEntry]) {
        self.addHomeFeed += userRecipes
    }
    
    //Add to removal set all recipes that are uploaded by the user that the logged
    //in user just unfollowed
    func unfollowRemoval(userID: String) {
        let recipesRef = Database.database().reference()
            .child("/users/\(userID)/uploaded")
        
        recipesRef.getData { error, snapshot in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            DispatchQueue.main.async {
                for recipeID in snapshot!.children {
                    guard let recipeIDItem = recipeID as? DataSnapshot else {
                        print("Error: Could not parse recipeID as DataSnapshot")
                        return
                    }
                    print("Unfollow: Queuing recipe id removal \(recipeIDItem.key)")
                    self.removeHomeFeed.insert(recipeIDItem.key)
                }
            }
        }
    }
    
    //User requests to refresh their home feed
    func doHomeFeedRefresh() {
        let rootRef = Database.database().reference()
        let recipesRef = rootRef.child("recipes")
        
        //Change video entries that have been changed on db
        for changed_id in changedHomeFeed {
            let changedRef = recipesRef.child(changed_id)
            changedRef.getData { error, snapshot in
                guard error == nil else {
                    print(error!.localizedDescription)
                    return
                }
                
                DispatchQueue.main.async {
                    guard let recipe_value = snapshot!.value as? NSDictionary else {
                        print("Error: recipe value cannot be cast as NSDictionary")
                        return
                    }
                    
                    guard let re = RecipeEntry.fromDict(recipe_value[changed_id] as! NSDictionary) else {
                        print("Error: RecipeEntry cannot be created from recipe value")
                        return
                    }
                    
                    let recipe_id = snapshot!.key
                    self.homeFeed[recipe_id] = re
                }
            }
        }
        self.changedHomeFeed = []
        
        //Add video entries that have been added to db
        for new_entry in self.addHomeFeed {
            if let id: String = new_entry.id {
                print("Adding id: \(id)")
                self.homeFeed[id] = new_entry
            } else {
                print("Could not add new entry: ID not found")
            }
        }
        self.addHomeFeed = []
        
        //Delete video entries that have been deleted on db
        //or from an unfollow
        print("Doing home feed refresh...")
        for removed_id in removeHomeFeed {
            print("Removing: \(removed_id)")
            let val = self.homeFeed.removeValue(forKey: removed_id)
            if val == nil {
                print("Could not remove value from home feed: Value does not exist in home feed")
            }
        }
        self.removeHomeFeed = []
    }
    
    func addRecipeEntry(entry: inout RecipeEntry, userId: String, imageData: NSData) {
        //Adding recipe entry to recipe tree
        let rootRef = Database.database().reference()
        let recipesRef = rootRef.child("recipes")
        let childRef = recipesRef.childByAutoId()
        entry.id = childRef.key
        if let val = entry.dict {
            childRef.setValue(val)
        } else {
            print("Error converting entry to dictionary value")
            return
        }
        
        //Append to uploaded by user
        let uploadedRef = rootRef.child("/users/\(userId)/uploaded")
        uploadedRef.child(entry.id!).setValue(1, withCompletionBlock: { error, _ in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
        })
        //upload recipe image
        uploadRecipeImage(userId: userId, recipeId: entry.id!, imageData: imageData)
    }
    
    //adds recipe image to Firebase Storage
    func uploadRecipeImage(userId: String, recipeId: String, imageData: NSData) {
        let storageRef = Storage.storage().reference()
        
        let testRef = storageRef.child("images/\(userId)/\(recipeId)/recipeImage.jpg")
        
        // Upload the file to the path /images/userId/recipeId/recipeImage
        testRef.putData(imageData as Data, metadata: nil) { (metadata, error) in
            guard let _ = metadata else {
                print(error!.localizedDescription)
                return
            }
            //success
        }
        
    }
    
    
}
