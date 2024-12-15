import SwiftUI

@main
struct ArDiary2App: App {
    
    @State private var model = ViewModel()
    @State private var selectedDate = Date()  // 선택된 날짜를 Date 타입으로 저장
    @State private var userId: String = "hata676"  // 사용자 ID
    @State private var diaryContent: String = ""  // 다이어리 내용
    
    var body: some Scene {
        WindowGroup {
            // PrimaryWindowView에 diaryContent를 바인딩하여 전달
            PrimaryWindowView(selectedDate: $selectedDate, userId: $userId, diaryContent: $diaryContent)
                .environment(model)
                .frame(
                    minWidth: 550, maxWidth: 550,
                    minHeight: 1300, maxHeight: 1300)
        }
        .defaultSize(CGSize(width: 550, height: 1300))
        .windowResizability(.contentSize)
        
        WindowGroup(id: "secondaryWindow") {
            // 선택된 날짜와 사용자 ID를 SecondaryWindowView로 전달 (selectedDate를 Binding으로 전달)
            SecondaryWindowView(id: userId, date: $selectedDate) {  // Binding<Date>로 변경
                // 클로저 안에서 할 작업을 정의합니다.
                print("Insert success!")
            }
            .environment(model)
        }
        
        WindowGroup(id : "_3DdiaryWindow") {
            // 다이어리 내용을 전달하여 3D 모델을 표시
            _3DDiaryView(diaryContent: $diaryContent)  // @Binding으로 전달
                .onAppear {
                    // diaryContent 값을 로그로 출력
                    print("Current diaryContent: \(diaryContent)")
                }
        }
        .windowStyle(.volumetric)
        .defaultSize(Size3D(width: 2.0, height: 0.2, depth: 0.01), in: .meters)
        .windowResizability(.contentMinSize)
    }
}
