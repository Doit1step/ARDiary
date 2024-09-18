import SwiftUI

struct SecondaryWindowView: View {
    
    @State private var id = ""
    @State private var date = ""
    @State private var diaryContent = ""
    
    @Environment(ViewModel.self) private var model
    
    var body: some View {
        VStack {
            TextField("Enter ID", text: $id)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Enter Date (YYYYMMDD)", text: $date)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Enter Diary Content", text: $diaryContent)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Submit") {
                insertData(id: id, date: date, diaryContent: diaryContent)
            }
            .padding()
        }
        .padding()
        .onDisappear {
            model.secondaryWindowIsShowing.toggle()
        }
    }
    
    func insertData(id: String, date: String, diaryContent: String) {
        guard let url = URL(string: "https://ha-labs.com/insert") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["ID": id, "DATE": date, "DIARY_CONTENT": diaryContent]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        // URLSession을 생성하고 NetworkManager를 delegate로 설정
        let session = URLSession(configuration: .default, delegate: NetworkManager.shared, delegateQueue: nil)

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
            } else if let httpResponse = response as? HTTPURLResponse {
                print("Response code: \(httpResponse.statusCode)")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Response data: \(responseString)")
                }
            }
        }.resume()
    }
}

#Preview {
    SecondaryWindowView()
        .environment(ViewModel())
}
