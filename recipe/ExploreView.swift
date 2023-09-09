//
//  ExploreView.swift
//  recipe
//
//  Created by Aaron Kong on 3/16/23.
//

import SwiftUI

struct ExploreViewElement: View {
    var recipe: RecipeEntry
    
    @State private var recipeImage: UIImage?
    @State private var pfp: UIImage?
    @State private var displayName: String = "Not Found"
    @Binding var userLoggedIn: Bool
    
    @State private var userLikedRecipe: Bool = false
    @State var likes: Int
    @State private var userBookmarkedRecipe: Bool = false
    @State var bookmarks: Int
    
    var body: some View {
        NavigationLink(destination: recipeDocumentView(
            image: $recipeImage,
            pfp: $pfp,
            displayName: $displayName,
            userLoggedIn: $userLoggedIn,
            userLikedRecipe: $userLikedRecipe,
            likes: $likes,
            userBookmarkedRecipe: $userBookmarkedRecipe,
            bookmarks: $bookmarks,
            recipeEntry: recipe)
            .onAppear {
                recipe.getRecipeImg(completion: handleImageDownloadResponse)
                AuthService.authservice.getIDsUsernamesMap(userIDs: [recipe.user], completion: getUsernameHandler)
                AuthService.authservice.userLikedRecipe(recipe.id!, completion: { result in
                    if result {
                        userLikedRecipe = true
                    }
                })
                AuthService.authservice.userBookmarkedRecipe(recipe.id!, completion: {
                    result in
                    if result {
                        userBookmarkedRecipe = true
                    }
                })
        }) {
            VStack {
                Text(recipe.name)
            }
        }
    }
    
    func handleImageDownloadResponse(response: Bool, data: Data?, error: Error?) {
        if !response && error != nil {
            print(error!.localizedDescription)
        } else if !response {
            print("Image could not be retrieved")
        } else {
            self.recipeImage = UIImage(data: data!)
        }
    }
    
    func getUsernameHandler(response: Bool, map: [String : String], message: String) {
        if response == true {
            let id = map.keys.first!
            self.displayName = map[id] ?? "Name not found"
        }
    }
}

struct ExploreView: View {
    @EnvironmentObject var recipeObserver: RecipeObserver
    @Binding var userLoggedIn: Bool
    @State private var searchText = ""
    @State private var filteredList: [RecipeEntry] = [] //filtered list of recipes based on searchText

    
    var body: some View {
        NavigationStack{
            List {
                ForEach(filteredList) { recipe in
                    ExploreViewElement(
                        recipe: recipe,
                        userLoggedIn: $userLoggedIn,
                        likes: recipe.getLikes(),
                        bookmarks: recipe.bookmarks)
                }
            }
            .navigationTitle("Explore")
        }
        .searchable(text: $searchText, prompt: "Search Recipes")
        .navigationViewStyle(.stack)
        .onChange(of: searchText) { newSearchText in 
            filteredList = Array(recipeObserver.allRecipes.values).filter() { entry in
                //filters by recipe name and ingredients
                entry.name.hasPrefix(newSearchText) ||
                containsIngredient(ingedients: entry.ingredients, searchText: newSearchText)
                
            }
        }
    }
    
    func containsIngredient(ingedients: [String], searchText: String) -> Bool {
        for ingredient in ingedients {
            if ingredient.hasPrefix(searchText) {
                return true
            }
        }
        return false
    }
    
}

struct ExploreView_Previews: PreviewProvider{
    static var previews: some View{
        ExploreView(userLoggedIn: .constant(false))
    }
}
