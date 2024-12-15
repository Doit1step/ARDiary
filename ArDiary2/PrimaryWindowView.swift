import SwiftUI


struct PrimaryWindowView: View {
    
    @Environment(ViewModel.self) var model
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    @State private var selectedDate = Date()
    @State private var textFieldInput = ""
    
    var body: some View {
    
        @Bindable var model = model
        
        VStack(alignment: .center, spacing: 18.0) {
            DatePicker(
                "Select a date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .padding()
            
            // 500x500 크기의 텍스트박스
            TextEditor(text: $textFieldInput)
                .frame(width: 500, height: 500)
                .border(Color.gray, width: 1)  // 경계선을 추가해서 텍스트박스를 강조
                .padding()
                
            Toggle("Open the secondary window", isOn: $model.secondaryWindowIsShowing)
                .toggleStyle(.button)

            Spacer()  // 상단에 정렬하기 위해 Spacer 추가
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)  // VStack 전체를 상단에 배치
        .onChange(of: model.secondaryWindowIsShowing) { _, isShowing in
            if isShowing {
                openWindow(id: "secondaryWindow")
            } else {
                dismissWindow(id: "secondaryWindow")
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    PrimaryWindowView()
        .environment(ViewModel())
}
 
