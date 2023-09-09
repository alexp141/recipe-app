import SwiftUI

struct ContentView: View {
    @EnvironmentObject var recipes: RecipeObserver
    @EnvironmentObject var userInfo: UserInformation
    @State var userLoggedIn: Bool = AuthService.authservice.userSignedIn()
    
    var body: some View {
        Group {
            if userLoggedIn {
                TabView {
                    HomeView(userLoggedIn: $userLoggedIn).tabItem {
                        Label("Home", systemImage: "house")
                    }
                    ExploreView(userLoggedIn: $userLoggedIn).tabItem {
                        Label("Explore", systemImage: "magnifyingglass")
                    }
                    PostView().tabItem {
                        Label("Post", systemImage: "plus")
                    }
                    MyRecipesView(userLoggedIn: $userLoggedIn).tabItem {
                        Label("My Recipes", systemImage: "bookmark")
                    }
                    AccountView(userLoggedIn: $userLoggedIn,
                                username: userInfo.userName!,
                                userID: userInfo.uid!)
                    .tabItem {
                        Label("Account", systemImage: "person")
                    }
                }
            } else {
                UserLoginView(userLoggedIn: $userLoggedIn)
            }
        }.onChange(of: userLoggedIn) { newValue in
            //Observer launcher/killer
            if userLoggedIn {
                recipes.launchObserver()
            } else {
                recipes.killObserver()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(RecipeObserver())
            .environmentObject(UserInformation())
    }
}
