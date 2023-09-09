import Foundation
import SwiftUI

struct ProfileImageView: View {
    @State var image: Image
    @State var width: CGFloat = 128
    @State var height: CGFloat = 128
    
    var body: some View  {
        image
            .resizable()
            .frame(width: width, height: height)
            .clipShape(Circle())
    }
}
