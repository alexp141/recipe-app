import SwiftUI

struct HomeView: View {
    @Binding var userLoggedIn: Bool
    @EnvironmentObject var recipes: RecipeObserver
    
    var body: some View {
            NavigationStack{
                HStack {
                    ScrollView {
                        if Array(recipes.homeFeed.values) == [] {
                            VStack(){
                                Text("No recipes found!")
                                Text("Find users to follow with the search icon!")
                            }
                        } else {
                            ForEach(Array(recipes.homeFeed.values), id: \.self) { recipe in
                                recipePreviewElementView(
                                    userLoggedIn: $userLoggedIn,
                                    likes: recipe.getLikes(),
                                    bookmarks: recipe.bookmarks,
                                    recipeEntry: recipe
                                )
                            }
                        }
                    }
                    .toolbar() {
                        Button(action: {
                            recipes.doHomeFeedRefresh()
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .navigationTitle("Home")
                }
            }
            .navigationViewStyle(.stack)
        }
    }

struct HomeView_Previews: PreviewProvider{
    static var previews: some View{
        HomeView(userLoggedIn: .constant(false))
            .environmentObject(RecipeObserver())
    }
}
