import SwiftUI

struct MyRecipesView: View {
    @EnvironmentObject var recipes: RecipeObserver
    @Binding var userLoggedIn: Bool
    
    var body: some View {
        NavigationStack{
            ScrollView {
                let r = recipes.bookmarkFeed.sorted {
                    (lhs: RecipeEntry, rhs: RecipeEntry) -> Bool in
                    return lhs.datetime < rhs.datetime
                }
                
                VStack {
                    ForEach(r, id: \.self) { i in
                        recipeGridPreview(
                            userLoggedIn: $userLoggedIn,
                            likes: i.getLikes(),
                            bookmarks: i.bookmarks,
                            recipeEntry: i
                        )
                        .frame(width: 1000)
                    }
                }
                .navigationTitle("Saved Recipes")
            }
            .onAppear() {
                recipes.doBookmarkRefresh()
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct MyRecipesView_Previews: PreviewProvider{
    static var previews: some View{
        MyRecipesView(userLoggedIn: .constant(false))
            .environmentObject(RecipeObserver())
    }
}
