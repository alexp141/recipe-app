//
//  recipePreviewElementView.swift
//  recipe
//
//  Created by Norman on 4/13/23.
//

import Foundation
import SwiftUI
import FirebaseDatabase

struct recipePreviewElementView : View {
    @EnvironmentObject var recipes: RecipeObserver
    
    @Binding var userLoggedIn: Bool
    @State var image: UIImage?
    @State var pfp: UIImage?
    @State var displayName: String = ""
    
    //Auth functions
    @State var userLikedRecipe: Bool = false
    @State var likes: Int
    @State var userBookmarkedRecipe: Bool = false
    @State var bookmarks: Int
    
    var recipeEntry: RecipeEntry
    
    func handleImageDownloadResponse(response: Bool, data: Data?, error: Error?) {
        if !response && error != nil {
            print(error!.localizedDescription)
        } else if !response {
            print("Image could not be retrieved")
        } else {
            image = UIImage(data: data!)
        }
    }
    
    func handleDisplayNameResponse(response: Bool, username: String?, error: Error?) {
        if !response && error != nil {
            print(error!.localizedDescription)
        } else if !response {
            print("Display name could not be retrieved")
        } else {
            displayName = username!
        }
    }
    
    func handleUserLikedRecipeResponse(liked: Bool) {
        //User already liked the recipe, so we unlike it
        if liked {
            //unlike
            AuthService.authservice.userUnlikeRecipe(recipeEntry.id ?? "")
        } else {
            //User did not previously like the recipe, so we like it
            AuthService.authservice.userLikeRecipe(recipeEntry.id ?? "")
        }
    }
    
    func handleUserBookmarkedRecipeResponse(bookmarked: Bool) {
        if bookmarked {
            //Unbookmark
            AuthService.authservice.userUnbookmarkRecipe(recipeEntry.id ?? "", completion: userUnbookmarkHandler)
        } else {
            //Bookmark
            AuthService.authservice.userBookmarkRecipe(recipeEntry.id ?? "", completion: userBookmarkHandler)
        }
    }
    
    //completion handler for userBookmarkRecipe()
    func userBookmarkHandler(response: Bool) {
        if response == true {
            print("User bookmarked recipe: Appending to bookmark feed")
            recipes.bookmarkFeed.append(recipeEntry)
        }
    }
    //completion handler for userUnbookmarkRecipe()
    func userUnbookmarkHandler(response: Bool) {
        if response == true, let idx = recipes.bookmarkFeed.firstIndex(of: recipeEntry) {
            print("User unbookmarked recipe, removing...")
            recipes.bookmarkFeed.remove(at: idx)
        }
    }
    
    func userProfilePictureHandler(result: Bool, imgData: Data?, err: Error?) {
        if !result && err == nil{
            print("Error retrieving profile picture")
        } else if !result {
            print(err!.localizedDescription)
        } else if imgData != nil {
            pfp = UIImage(data: imgData!)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            //will lead to the other user's profile
            NavigationLink(destination: AccountView(
                userLoggedIn: $userLoggedIn,
                username: displayName,
                userID: recipeEntry.user)) {
                HStack {
                    //profile pic
                    if pfp != nil {
                        ProfileImageView(image: Image(uiImage: pfp!), width: 45, height: 45)
                    } else {
                        ProfileImageView(image: Image(systemName: "person.crop.circle"), width: 45, height: 45)
                    }
                    VStack(alignment: .leading) {
                        Text(displayName)
                        Text(recipeEntry.datetime)
                    }
                    Spacer()
                }
            }.buttonStyle(PlainButtonStyle())
            
            //Taps here will lead to recipe viewer
            NavigationLink(destination: recipeDocumentView(
                image: $image,
                pfp: $pfp,
                displayName: $displayName,
                userLoggedIn: $userLoggedIn,
                userLikedRecipe: $userLikedRecipe,
                likes: $likes,
                userBookmarkedRecipe: $userBookmarkedRecipe,
                bookmarks: $bookmarks,
                recipeEntry: self.recipeEntry)) {
                
                if image == nil {
                    Rectangle()
                        .fill(Color.black)
                        .border(.black)
                        .frame(width: .none, height: 375)
                        .overlay() {
                            Text("Image could not be retrieved")
                                .foregroundColor(Color.white)
                        }
                } else {
                    Image(uiImage: image!)
                        .resizable()
                        .frame(width: .none, height: 375)
                }
            }
            
            Text(recipeEntry.name).font(.title).padding(.leading)
            Text(recipeEntry.description).multilineTextAlignment(.leading).padding(.leading)
            
            HStack {
                HStack {
                    Button {
                        //Note: User changes will affect the state of the views locally
                        //If something were to go wrong, the view will still show that we
                        //liked or unliked it, but it should correct itself if we do a refresh
                        userLikedRecipe.toggle()
                        if userLikedRecipe {
                            likes += 1
                        } else {
                            likes -= 1
                        }
                        //Check if we liked the recipe on db and handle response
                        AuthService.authservice.userLikedRecipe(
                            recipeEntry.id!,
                            completion: handleUserLikedRecipeResponse
                        )
                    } label: {
                        if userLikedRecipe {
                            Image(systemName: "heart.fill").frame(width: 45, height: 45).aspectRatio(contentMode: .fill)
                        } else {
                            Image(systemName: "heart").frame(width: 45, height: 45).aspectRatio(contentMode: .fill)
                        }
                        Text(likes.description)
                    }.foregroundColor(Color.black)
                    
                }.padding()
                HStack {
                    Image(systemName: "message").frame(width: 45, height: 45).aspectRatio(contentMode: .fill)
                    Text("0")
                }.padding()
                HStack {
                    Button {
                        userBookmarkedRecipe.toggle()
                        if userBookmarkedRecipe {
                            bookmarks += 1
                        } else {
                            bookmarks -= 1
                        }
                        AuthService.authservice.userBookmarkedRecipe(recipeEntry.id!, completion: handleUserBookmarkedRecipeResponse)
                    } label: {
                        if userBookmarkedRecipe {
                            Image(systemName: "bookmark.fill").frame(width: 45, height: 45).aspectRatio(contentMode: .fill)
                        } else {
                            Image(systemName: "bookmark").frame(width: 45, height: 45).aspectRatio(contentMode: .fill)
                        }
                        Text(bookmarks.description)
                    }.foregroundColor(Color.black)
                    
                }.padding()
            }
            
        }.onAppear {
            AuthService.authservice.userLikedRecipe(recipeEntry.id!, completion: { result in
                if result {
                    userLikedRecipe = true
                } else {
                    userLikedRecipe = false
                }
            })
            
            AuthService.authservice.userBookmarkedRecipe(recipeEntry.id!, completion: {
                result in
                if result {
                    userBookmarkedRecipe = true
                } else {
                    userBookmarkedRecipe = false
                }
            })
            
            recipeEntry.getRecipeImg(completion: handleImageDownloadResponse)
            getProfilePicture(userID: recipeEntry.user, completion: userProfilePictureHandler)
            getDisplayName(recipeEntry.user, completion: handleDisplayNameResponse)
        }
    }
}

struct recipePreviewElement_Previews: PreviewProvider {
    static var previews: some View {
        recipePreviewElementView(
            userLoggedIn: .constant(false),
            image: UIImage(systemName: "doc.plaintext"),
            likes: 2,
            bookmarks: 0,
            recipeEntry: RecipeEntry(
                id: "DNE",
                name: "name",
                user: "user",
                description: "description",
                ingredients: ["ing1", "ing2"],
                directions: ["dir1", "dir2"],
                likes: ["user2": 1, "user3": 1],
                bookmarks: 0,
                datetime: Date.distantPast.formatted(),
                comments: [:]
        ))
    }
}
