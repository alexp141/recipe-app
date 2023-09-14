import Foundation
import SwiftUI

struct recipeGridPreview: View {
    @State var image: UIImage?
    @State var displayName: String = ""
    @Binding var userLoggedIn: Bool
    @State var pfp: UIImage?
    
    @State var userLikedRecipe: Bool = false
    @State var likes: Int
    @State var userBookmarkedRecipe: Bool = false
    @State var bookmarks: Int
    
    var recipeEntry: RecipeEntry
    
    func handleDisplayNameResponse(response: Bool, username: String?, error: Error?) {
        if !response && error != nil {
            print(error!.localizedDescription)
        } else if !response {
            print("Display name could not be retrieved")
        } else {
            displayName = username!
        }
    }
    
    var body: some View {
        NavigationLink(destination: recipeDocumentView(
            image: $image,
            pfp: $pfp,
            displayName: $displayName,
            userLoggedIn: $userLoggedIn,
            userLikedRecipe: $userLikedRecipe,
            likes: $likes,
            userBookmarkedRecipe: $userBookmarkedRecipe,
            bookmarks: $bookmarks,
            recipeEntry: recipeEntry)) {
            VStack {
                if image == nil {
                    Rectangle()
                        .fill(Color.black)
                        .border(.black)
                        .frame(width: 100, height: 100)
                        .overlay() {
                            Text("Image could not be retrieved")
                                .foregroundColor(Color.white)
                        }
                } else {
                    Image(uiImage: image!)
                        .resizable()
                        .frame(width: 100, height: 100)
                }
                Text(recipeEntry.name)
            }
            .frame(width: 125, height: 150)
            .padding(8)
            .cornerRadius(10)
            .overlay( /// rounded border
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.gray, lineWidth: 2)
            )
            .onAppear() {
                recipeEntry.getRecipeImg(completion: handleGetRecipeImgResponse)
                getDisplayName(recipeEntry.user, completion: handleDisplayNameResponse)
                
                AuthService.authservice.userLikedRecipe(recipeEntry.id!, completion: { result in
                    if result {
                        userLikedRecipe = true
                    }
                })
                AuthService.authservice.userBookmarkedRecipe(recipeEntry.id!, completion: {
                    result in
                    if result {
                        userBookmarkedRecipe = true
                    }
                })
            }
        }
    }
    
    func handleGetRecipeImgResponse(response: Bool, data: Data?, error: Error?) {
        if response == true && data != nil {
            image = UIImage(data: data!)
        }
    }
}

struct recipeGridPreviewElement_Previews: PreviewProvider {
    static var previews: some View {
        recipeGridPreview(
            userLoggedIn: .constant(false),
            likes: 2,
            bookmarks: 0,
            recipeEntry: RecipeEntry(
                id: "DNE",
                name: "Name",
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
