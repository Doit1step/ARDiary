import SwiftUI

@main
struct ArDiary2App: App {
    @State private var model = ViewModel()
    
    var body: some Scene {
        WindowGroup {     
            PrimaryWindowView()
                .environment(model)
                .frame(
                    minWidth: 500, maxWidth: 500,
                    minHeight: 1300, maxHeight: 1300)
        }
        .defaultSize(CGSize(width: 500, height: 1300))
        .windowResizability(.contentSize)
        
        WindowGroup(id: "secondaryWindow") {
            SecondaryWindowView()
                .environment(model)
        }
    }
}
