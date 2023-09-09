import SwiftUI

struct followButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .foregroundColor(Color.blue)
            .overlay(
                Capsule()
                    .stroke(Color.blue, lineWidth: 2)
            )
    }
}

struct unfollowButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .background(
                Capsule()
                    .fill(Color.blue)
            )
    }
}

struct AccountView: View {
    @EnvironmentObject var recipes: RecipeObserver
    
    @Binding var userLoggedIn: Bool
    @State var followers: [String] = []
    @State var following: [String] = []
    @State var followerCount: Int = 0
    @State var followingCount: Int = 0
    @State var postedRecipes: [RecipeEntry] = []
    @State var uiImage: UIImage?
    
    @State var isFollowing: Bool = false
    
    
    var username: String
    var userID: String
    
    
    func handleLogOutResponse(response: Bool, error: Error?) {
        //TODO: Status messages for logout errors
        if !response && error != nil {
            return
        } else if !response {
            return
        } else {
            //Log out and kill observer
            userLoggedIn = false
        }
    }

    func getFollowerHandler(response: Bool, followers: [String]) {
        if response {
            self.followers = followers
            followerCount = self.followers.count
        } else {
            print("Failed to get follower list")
        }
    }
    
    func getFollowingHandler(response: Bool, following: [String]) {
        if response {
            self.following = following
            followingCount = self.following.count
        } else {
            print("Failed to following list")
        }
    }
    
    func handleUploadedRecipeEntries(response: Bool, recipeEntries: [RecipeEntry]) {
        if response {
            postedRecipes = recipeEntries
        } else {
            print("Could not parse recipe uploads")
        }
    }
    
    func handleProfilePictureResponse(response: Bool, data: Data?, error: Error?) {
        if !response && error != nil {
            print(error!.localizedDescription)
        } else if !response {
            print("Error fetching profile picture")
        } else {
            uiImage = UIImage(data: data!)
        }
    }
    
    func handleIfFollowingResponse(following: Bool, msg: String) {
        print(msg)
        isFollowing = following
    }
    
    func userFollowedHandler(response: Bool, message: String) {
        if response == true {
            self.followerCount += 1 //update follower count
            self.isFollowing = true
            AuthService.authservice.getUploadedRecipeEntries(userID: userID) { response, recipies in
                recipes.followAdd(userRecipes: recipies)
            }
            
            print(message)
        }
        else {
            
            print(message)
        }
    }
        
    func userUnfollowedHandler(response: Bool, message: String) {
        if response == true {
            self.followerCount -= 1 //update follower count
            self.isFollowing = false
            recipes.unfollowRemoval(userID: userID)
            print(message)
        }
        else {
            print(message)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .center) {
                    HStack {
                        Spacer()
                    }
                    if uiImage != nil {
                        ProfileImageView(image: Image(uiImage: uiImage!))
                    } else {
                        ProfileImageView(image: Image(systemName: "person.crop.circle"))
                    }
                    Text("\(username)")
                        .bold()
                    
                    //followers, following
                    HStack {
                        NavigationLink(destination: AccountList(
                            userLoggedIn: $userLoggedIn,
                            user: userID,
                            listType: .followers)) {
                            VStack {
                                Text("Followers")
                                Text("\(followerCount)")
                            }
                            
                        }
                        .buttonStyle(followButton())
                        
                        NavigationLink(destination: AccountList(
                            userLoggedIn: $userLoggedIn,
                            user: userID,
                            listType: .following)) {
                            VStack {
                                Text("Following")
                                Text("\(followingCount)")
                            }
                        }
                        .buttonStyle(followButton())
                        
                    }
                    //Log out option if this is the user's account
                    if userID == AuthService.authservice.getCurrentUserId() {
                        Button("Log out") {
                            AuthService.authservice.userSignOut(completion: handleLogOutResponse)
                        }
                    } else {
                        //Follow button
                        //Same as likes, bookmarks, etc.
                        //Local updates: if something goes wrong,
                        //it will revert upon refresh
                        if isFollowing {
                            Button("Unfollow") {
                                AuthService.authservice.userUnfollowed(otherUserID: userID, completion: userUnfollowedHandler)
                            }
                            .buttonStyle(unfollowButton())
                        } else {
                            Button("Follow") {
                                AuthService.authservice.userFollowed(otherUserID: userID, completion: userFollowedHandler)
                            }
                            .buttonStyle(followButton())
                        }
                    }
                    if postedRecipes == [] {
                        Text("No uploaded recipes found")
                    } else {
                        ForEach(postedRecipes.sorted {
                            (lhs: RecipeEntry, rhs: RecipeEntry) -> Bool in
                            return lhs.datetime < rhs.datetime
                        }, id: \.self) { post in
                            VStack {
                                recipeGridPreview(
                                    userLoggedIn: $userLoggedIn,
                                    likes: post.getLikes(),
                                    bookmarks: post.bookmarks,
                                    recipeEntry: post
                                )
                            }
                        }
                    }
                }
                .onAppear() {
                    AuthService.authservice.getFollowersIDs(userID: userID, completion: getFollowerHandler)
                    AuthService.authservice.getFollowingIDs(userID: userID, completion: getFollowingHandler)
                    getProfilePicture(userID: userID, completion: handleProfilePictureResponse)
                    if userID != AuthService.authservice.getCurrentUserId() {
                        AuthService.authservice.checkIfFollowing(otherUserID: userID, completion: handleIfFollowingResponse)
                    }
                    
                    AuthService.authservice.getUploadedRecipeEntries(userID: userID, completion: handleUploadedRecipeEntries)
                    
                }
            }
        }
    }
}

struct AccountView_Previews: PreviewProvider{
    static var previews: some View{
        AccountView(
            userLoggedIn: .constant(false),
            postedRecipes: [],
            isFollowing: false,
            username: "Test username",
            userID: "Not a real id"
            )
            .environmentObject(RecipeObserver())
            .environmentObject(UserInformation())
    }
}
