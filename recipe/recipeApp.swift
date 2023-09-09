import SwiftUI
import Firebase

@main
struct recipeApp: App {
    @StateObject var recipes: RecipeObserver = RecipeObserver()
    @StateObject var userInfo: UserInformation = UserInformation()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(recipes)
                .environmentObject(userInfo)
        }
    }
}
