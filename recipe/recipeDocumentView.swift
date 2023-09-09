import Foundation
import SwiftUI

struct recipeDocumentView: View {
    @EnvironmentObject var recipes: RecipeObserver
    
    @State var commentContent: String = ""
    @State var alertTitle: String = ""
    @State var showcommentResponseAlert: Bool = false
    @State var comments: [Comment] = []
    
    @Binding var image: UIImage?
    @Binding var pfp: UIImage?
    @Binding var displayName: String
    @Binding var userLoggedIn: Bool
    
    @Binding var userLikedRecipe: Bool
    @Binding var likes: Int
    @Binding var userBookmarkedRecipe: Bool
    @Binding var bookmarks: Int
    
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
    
    func handleUserMakeCommentResponse(response: Bool, error: Error?, comment: Comment?) {
        showcommentResponseAlert = true
        if response, let comment = comment {
            alertTitle = "Comment Posted"
            comments.append(comment)
            commentContent = ""
        } else {
            alertTitle = "Error"
        }
    }
    
    func handleProfilePictureResponse(response: Bool, data: Data?, err: Error?) {
        if !response && err != nil {
            print(err!.localizedDescription)
        } else if !response {
            print("Error retrieving profile picture")
        } else if data != nil {
            pfp = UIImage(data: data!)
        }
    }
    
    func handleUserLikedRecipeResponse(liked: Bool) {
        //User already liked the recipe, so we unlike it
        if liked {
            //unlike
            AuthService.authservice.userUnlikeRecipe(recipeEntry.id!)
        } else {
            //User did not previously like the recipe, so we like it
            AuthService.authservice.userLikeRecipe(recipeEntry.id!)
        }
    }
    
    func handleUserBookmarkedRecipeResponse(bookmarked: Bool) {
        if bookmarked {
            //Unbookmark
            AuthService.authservice.userUnbookmarkRecipe(recipeEntry.id!, completion: userUnbookmarkHandler)
        } else {
            //Bookmark
            AuthService.authservice.userBookmarkRecipe(recipeEntry.id!, completion: userBookmarkHandler)
        }
    }
    
    //completion handler for userBookmarkRecipe()
    func userBookmarkHandler(response: Bool) {
        //Prevent duplicate entries
        if response == true && !recipes.bookmarkFeed.contains(where: {elt in  elt.id! == recipeEntry.id!}){
            recipes.bookmarkFeed.append(recipeEntry)
        }
        recipes.bookmarkRemove.removeAll(where: {re in re.id! == recipeEntry.id! })
    }
    //completion handler for userUnbookmarkRecipe()
    func userUnbookmarkHandler(response: Bool) {
        if response == true {
            recipes.bookmarkRemove.append(recipeEntry)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack (alignment: .leading) {
                Group {
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
                    
                    NavigationLink(destination:
                                    AccountView(
                                        userLoggedIn: $userLoggedIn,
                                        username: displayName,
                                        userID: recipeEntry.user)
                    ) {
                        HStack {
                            if pfp != nil {
                                ProfileImageView(image: Image(uiImage: pfp!), width: 45, height: 45)
                            } else {
                                //Attempt to resolve a pfp if this appears
                                ProfileImageView(image: Image(systemName: "person.crop.circle"), width: 45, height: 45)
                                    .onAppear() {
                                        getProfilePicture(userID: recipeEntry.user, completion: handleProfilePictureResponse)
                                    }
                            }
                            Text("\(displayName)")
                    }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .font(.largeTitle)
                    
                    HStack {
                        Button {
                            userLikedRecipe.toggle()
                            if userLikedRecipe {
                                likes += 1
                            } else {
                                likes -= 1
                            }
                            AuthService.authservice.userLikedRecipe(
                                recipeEntry.id!,
                                completion: handleUserLikedRecipeResponse
                            )
                        } label : {
                            if userLikedRecipe {
                                Image(systemName: "heart.fill")
                            } else {
                                Image(systemName: "heart")
                            }
                        }
                        .foregroundColor(Color.black)
                        
                        Button {
                            userBookmarkedRecipe.toggle()
                            if userBookmarkedRecipe {
                                bookmarks += 1
                            } else {
                                bookmarks -= 1
                            }
                            AuthService.authservice.userBookmarkedRecipe(
                                recipeEntry.id!,
                                completion: handleUserBookmarkedRecipeResponse
                            )
                        } label: {
                            if userBookmarkedRecipe {
                                Image(systemName: "bookmark.fill")
                            } else {
                                Image(systemName: "bookmark")
                            }
                            
                        }
                        .foregroundColor(Color.black)
                        
                    }.font(.title)
                    Divider()
                }
                Group {
                    Text("Description: ")
                        .font(.title)
                        .bold()
                    Text(recipeEntry.description)
                    Divider()
                }
                
                Group {
                    Text("Ingredients:")
                        .font(.title)
                        .bold()
                    
                    ForEach(recipeEntry.ingredients, id: \.self) { ingredient in
                        Text(ingredient)
                    }
                    Divider()
                }
                
                Group {
                    Text("Directions:")
                        .font(.title)
                        .bold()
                    
                    ForEach(recipeEntry.directions, id: \.self) { direction in
                        Text(direction)
                    }
                    Divider()
                }
                Group {
                    Text("Comments:").bold()
                    ForEach(self.comments, id: \.self) { comment in
                        HStack {
                            Image(systemName: "message.fill")
                            Text(comment.content)
                        }
                    }
                }.onAppear {
                    self.comments = recipeEntry.comments.values.map {$0}
                }
            }
            
            TextField("Post a comment", text: $commentContent)
                .border(Color.black)
            
            Button("Post comment") {
                guard !commentContent.isEmpty else { return }
                AuthService.authservice.userMakeComment(
                    recipeID: recipeEntry.id,
                    contents: commentContent,
                    completion: handleUserMakeCommentResponse)
            }.frame(width: 150, height: 35).background(.blue).cornerRadius(10).foregroundColor(.white)
            .alert(
                alertTitle,
                isPresented: $showcommentResponseAlert
            ) {
                Button(){
                } label: {
                    Text("Ok")
                }
            }
            .navigationTitle(recipeEntry.name)
        }
        .onDisappear() {
            recipes.doBookmarkRefresh()
        }
    }
}

struct recipeDocument_Previews: PreviewProvider {
    static var previews: some View {
        recipeDocumentView(
            image: .constant(nil),
            pfp: .constant(nil),
            displayName: .constant("User display name"),
            userLoggedIn: .constant(false),
            userLikedRecipe: .constant(false),
            likes: .constant(1),
            userBookmarkedRecipe: .constant(false),
            bookmarks: .constant(2),
            recipeEntry:
            RecipeEntry(
                name: "A recipe name",
                user: "notrealid123",
                description: "description",
                ingredients: ["ing1", "ing2"],
                directions: ["dir1", "dir2"],
                likes: ["user2": 1],
                bookmarks: 2,
                datetime: Date.distantPast.formatted(),
                comments: ["user2":Comment(user: "id",
                                           datetime: Date.distantPast.formatted(),
                                           content: "This is a test comment")]
            )
        )
    }
}

