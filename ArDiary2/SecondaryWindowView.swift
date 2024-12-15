import SwiftUI

struct SecondaryWindowView: View {
    
    @State private var diaryContent = ""
    
    @Environment(ViewModel.self) private var model  // ViewModel을 사용하여 상태 관리
    
    var id: String  // PrimaryWindowView에서 전달된 ID
    @Binding var date: Date  // PrimaryWindowView에서 전달된 선택된 날짜 (Date 타입으로 변경)
    var onInsertSuccess: () -> Void  // 삽입 성공 시 호출될 클로저
    
    var body: some View {
        VStack {
            TextEditor(text: $diaryContent)
                .padding()
                .frame(height: 150)  // 적절한 높이 설정
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .cornerRadius(8)
                .padding()
            
            Button("Save") {
                insertData(id: id, date: formatDate(date), diaryContent: diaryContent)  // 날짜 변환해서 전달
            }
            .padding()
        }
        .padding()
        .onDisappear {
                model.secondaryWindowIsShowing = false
        }
    }
    
    // 데이터 삽입 함수
    func insertData(id: String, date: String, diaryContent: String) {
        guard let url = URL(string: "https://ha-labs.com/insert") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["ID": id, "DATE": date, "DIARY_CONTENT": diaryContent]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let session = URLSession(configuration: .default, delegate: NetworkManager.shared, delegateQueue: nil)
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error: \(error)")
                    showErrorPopup(message: "Failed to insert data: \(error.localizedDescription)")
                } else if let httpResponse = response as? HTTPURLResponse {
                    print("Response code: \(httpResponse.statusCode)")
                    if httpResponse.statusCode == 200 {
                        print("Data inserted successfully")
                        model.secondaryWindowIsShowing = false  // 성공 시 창 닫기
                        model.startFetchData.toggle()  // PrimaryWindowView가 데이터를 다시 불러오도록 상태 변경
                        onInsertSuccess()  // 추가적인 동작이 필요하면 이 클로저 안에서 처리
                    } else {
                        print("Failed to insert data with response code: \(httpResponse.statusCode)")
                        showErrorPopup(message: "Failed to insert data: \(httpResponse.statusCode)")
                    }
                }
            }
        }.resume()
    }
    
    // 오류 팝업 호출 함수
    func showErrorPopup(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        // UIWindowScene을 통해 window 가져오기
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true, completion: nil)
        } else {
            print("No valid window scene found to present the alert.")
        }
    }
    
    // 날짜를 YYYYMMDD 형식으로 변환하는 함수
    func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        return dateFormatter.string(from: date)
    }
}
