import SwiftUI

enum ListType {
    case followers
    case following
}

struct AccountList: View {
    @Binding var userLoggedIn: Bool
    var user: String
    var listType: ListType
    
    //Format: USERID : Screen name
    @State var accs: [String:String] = [:]
    
    var body: some View {
        List {
            ForEach(Array(accs.keys), id: \.self) { userID in
                NavigationLink(destination: AccountView(userLoggedIn: $userLoggedIn, username: accs[userID]!, userID: userID)) {
                    Text(accs[userID]!)
                }
            }
        }.onAppear() {
            switch listType {
            case .followers:
                AuthService.authservice.getFollowersMap(userID: self.user, completion: getAccountsHandler)
            case .following:
                AuthService.authservice.getFollowingMap(userID: self.user, completion: getAccountsHandler)
            }
        }
    }
    
    func getAccountsHandler(response: Bool, usernames: [String:String], message: String) {
        if response == true {
            self.accs = usernames
            print(message)
        }
        else {
            print(message)
        }
    }
}

struct ShowFollowers_Previews: PreviewProvider {
    static var previews: some View {
        AccountList(userLoggedIn: .constant(false),
                    user: "aaaaaa",
                    listType: .followers)
    }
}
