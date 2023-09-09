import SwiftUI
import PhotosUI

struct PostView: View {
    @EnvironmentObject var recipes: RecipeObserver
    
    @State private var recipeName: String = ""
    @State private var description: String = ""
    @State private var ingredients: [String] = [""]
    @State private var directions: [String] = [""]
    
    //holds selected photos from photo library (not actual images)
    @State private var selectedPhotos: [PhotosPickerItem]  = []
    @State private var selectedImage: UIImage?
    @State private var imageData: NSData?
    @State private var recipeSubmitted = false
    
    //For array entries, every string elt should contain
    //non-whitespace text
    func validStringArray(_ arr: [String]) -> Bool {
        for stringElt in arr {
            let trimmed = stringElt.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                return false
            }
        }
        return true
    }
    
    var body: some View {
        NavigationView{
            Form {
                
                Section(header: Text("Recipe Name")){
                    TextField("Recipe Name", text: $recipeName)
                }
                
                Section(header: Text("Description")){
                    TextField("Description", text: $description)
                }
                
                Section(header: Text("Upload Image")){
                    if let selectedImage = self.selectedImage {
                        Image(uiImage: selectedImage).resizable().aspectRatio(contentMode: .fit)
                        
                    }
                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 1, matching: .images) {
                        Text("Upload Photo")
                    }.onChange(of: self.selectedPhotos) { newVal in
                        loadTransferable(from: newVal.first!)
                    }
                }
                
                Section(header: Text("Ingredients")){ // use list?
                    List {
                        ForEach(ingredients.indices, id: \.self) { idx in
                            TextField("New Ingredient", text: $ingredients[idx])
                        }
                        
                        Button("+ New Ingredient") {
                            ingredients.append("")
                        }
                    }
                    
                    
                }
                
                Section(header: Text("Directions")){ // use Llist
                    List {
                        ForEach(directions.indices, id: \.self) { idx in
                            TextField("New Step", text: $directions[idx])
                        }
                        
                        Button("+ Step") {
                            directions.append("")
                        }
                    }
                }
                
                // add save feature for form
                Section {
                    HStack {
                        Spacer()
                        Button("Upload Recipe") {
                            //Check valid input
                            guard !recipeName.isEmpty else { return }
                            guard !description.isEmpty else { return }
                            guard validStringArray(ingredients) else { return }
                            guard validStringArray(directions) else { return }
                            
                            guard let userId = AuthService.authservice.getCurrentUserId() else {
                                print("Error: Auth service could not get user id")
                                return
                            }
                            
                            guard let imageData = self.imageData else {
                                print("Error: Could not get image data")
                                return
                            }
                            
                            var recipeToUpload = RecipeEntry(
                                name: recipeName,
                                user: userId,
                                description: description,
                                ingredients: ingredients,
                                directions: directions,
                                likes: [:],
                                bookmarks: 0,
                                datetime: Date.now.formatted(),
                                comments: [:])
                            
                            recipes.addRecipeEntry(entry: &recipeToUpload, userId: userId, imageData: imageData) //uploads recipe to realtime db and image to firebase storage
                            self.recipeSubmitted = true
                        }.frame(width: 150, height: 35).background(.blue).cornerRadius(10).foregroundColor(.white)
                            .alert("Recipe Uploaded", isPresented: $recipeSubmitted) {
                                Button("Okay") {
                                    self.recipeSubmitted = false //reset
                                    self.recipeName = ""
                                    self.description = ""
                                    self.ingredients = [""]
                                    self.directions = [""]
                                    self.selectedImage = nil
                                    self.imageData = nil
                                }
                            } message: {
                                Text("Your recipe has been uploaded")
                            }
                            
                        Spacer()
                    }
                }
            }
            .navigationTitle("Upload Your Recipe")
        }
        .navigationViewStyle(.stack)
        
        
    }
    
    //used to transform a PhotosPickerItem into an actual photo
    func loadTransferable(from selectedImage: PhotosPickerItem) {
        selectedImage.loadTransferable(type: Data.self) { result in
            guard selectedImage == self.selectedPhotos.first else { return }
            
            switch result {
            case .success(let data?):
                // retrieved image data
                print("data is \(data.description)")
                self.selectedImage = UIImage(data: data) //image of the recipe after it has been converted
                self.imageData = NSData(data: data) //image as NSData so that we can store it in firebase storage
            case .success(nil):
                // empty value
                print("empty value")
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
}

struct PostView_Previews: PreviewProvider{
    static var previews: some View{
        PostView()
    }
}

