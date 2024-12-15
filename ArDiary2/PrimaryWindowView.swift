import SwiftUI
import RealityKit
import ARKit

enum AlertType {
    case serverError
    case instanceError
    case none
}

struct PrimaryWindowView: View {
    
    @Environment(ViewModel.self) var model
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    @Binding var selectedDate: Date
    @Binding var userId: String
    @Binding var diaryContent: String
    @State private var showAddButton = false
    @State private var alertType: AlertType = .none
    @State private var showAlert = false
    @State private var diaryDates: Set<Date> = []
    @State private var currentMonth: Date = Date()
    @State private var isVolumeOpen: Bool = false
    @State private var show3DDiary: Bool = false  // 3D Diary 보기 상태 변수 추가
    
    var body: some View {
        VStack(alignment: .center, spacing: 18.0) {
            // 상단 달력 제목과 이전/다음 버튼
            HStack {
                Button(action: {
                    currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    fetchDataForAllDates()
                }) {
                    Image(systemName: "chevron.left")
                        .padding()
                }
                Spacer()
                Text(monthYearString(currentMonth))
                    .font(.title2)
                    .bold()
                Spacer()
                Button(action: {
                    currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    fetchDataForAllDates()
                }) {
                    Image(systemName: "chevron.right")
                        .padding()
                }
            }
            .padding(.horizontal)
            .padding(.vertical)
            
            // 커스텀 캘린더
            CustomCalendarView(selectedDate: $selectedDate, currentMonth: $currentMonth, diaryDates: diaryDates, fetchDataForAllDates: fetchDataForAllDates)
                .padding()
                .onChange(of: selectedDate) { _, newDate in
                    let formattedDate = formatDate(newDate)
                    fetchData(id: userId, date: formattedDate)
                }
                .onAppear {
                    selectedDate = Date()
                    let formattedDate = formatDate(selectedDate)
                    fetchDataForAllDates()
                    fetchData(id: userId, date: formattedDate)
                }
            
            if showAddButton {
                Button(action: {
                    model.secondaryWindowIsShowing.toggle()
                    openWindow(id: "secondaryWindow")
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.largeTitle)
                }
                .padding()
            } else {
                ScrollView {
                    Text(diaryContent)
                        .frame(width: 500, height: 500, alignment: .top) // frame에서 alignment를 center로 설정
                        .multilineTextAlignment(.center) // 텍스트를 중앙 정렬
                        .border(Color.gray, width: 1)
                        .padding()
                }
                
                // "Show 3D Diary" 버튼 추가
                Button(action: {
                    print("3D 다이어리 보기 기능 실행")
                    if show3DDiary {
                        dismissWindow(id: "_3DdiaryWindow")
                        show3DDiary = false
                    } else {
                        openWindow(id: "_3DdiaryWindow")
                        show3DDiary = true
                    }
                    
                }) {
                    Text("Show 3D Diary")
                        .font(.headline)
                        .padding()
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .alert(isPresented: $showAlert) {
            switch alertType {
            case .serverError:
                return Alert(
                    title: Text("Server Error"),
                    message: Text("502: Contact us Via email (hata676@naver.com)"),
                    dismissButton: .default(Text("OK"))
                )
            case .instanceError:
                return Alert(
                    title: Text("EC2 Instance Error"),
                    message: Text("503: Contact us Via email (hata676@naver.com)"),
                    dismissButton: .default(Text("OK"))
                )
            case .none:
                return Alert(
                    title: Text("Unknown Error"),
                    message: Text("An unknown error occurred."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onChange(of: model.secondaryWindowIsShowing) { _, isShowing in
            if isShowing {
                openWindow(id: "secondaryWindow")
            } else {
                dismissWindow(id: "secondaryWindow")
            }
        }
        .onChange(of: model.startFetchData) { _, newValue in
            let formattedDate = formatDate(selectedDate)
            fetchData(id: userId, date: formattedDate)
        }
    }
    
    func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        return dateFormatter.string(from: date)
    }
    
    func fetchData(id: String, date: String) {
        guard let url = URL(string: "https://ha-labs.com/fetch?ID=\(id)&DATE=\(date)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
            } else if let httpResponse = response as? HTTPURLResponse {
                DispatchQueue.main.async {
                    print("Response code: \(httpResponse.statusCode)")
                    if httpResponse.statusCode == 200 {
                        if let data = data {
                            do {
                                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                                    if let firstEntry = jsonArray.first,
                                       let diaryContentResponse = firstEntry["DIARY_CONTENT"] as? String {
                                        diaryContent = diaryContentResponse
                                        showAddButton = false
                                        diaryDates.insert(selectedDate)
                                    } else {
                                        diaryContent = ""
                                        showAddButton = true
                                    }
                                }
                            } catch {
                                print("Error parsing JSON: \(error)")
                            }
                        }
                    } else if httpResponse.statusCode == 404 {
                        diaryContent = ""
                        showAddButton = true
                    } else if httpResponse.statusCode == 502 {
                        alertType = .serverError
                        showAlert = true
                    } else if httpResponse.statusCode == 503 {
                        alertType = .instanceError
                        showAlert = true
                    }
                }
            }
        }.resume()
    }
    
    func fetchDataForAllDates() {
        let firstDayOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: currentMonth))!
        let range = Calendar.current.range(of: .day, in: .month, for: currentMonth)!
        
        for day in range {
            let currentDate = Calendar.current.date(byAdding: .day, value: day - 1, to: firstDayOfMonth)!
            let formattedDate = formatDate(currentDate)
            fetchDataForDate(currentDate, id: userId, date: formattedDate)
        }
    }
    
    func fetchDataForDate(_ currentDate: Date, id: String, date: String) {
        guard let url = URL(string: "https://ha-labs.com/fetch?ID=\(id)&DATE=\(date)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
            } else if let httpResponse = response as? HTTPURLResponse {
                DispatchQueue.main.async {
                    if httpResponse.statusCode == 200 {
                        if let data = data {
                            do {
                                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                                    if let firstEntry = jsonArray.first,
                                       let _ = firstEntry["DIARY_CONTENT"] as? String {
                                        diaryDates.insert(currentDate)
                                    }
                                }
                            } catch {
                                print("Error parsing JSON: \(error)")
                            }
                        }
                    }
                }
            }
        }.resume()
    }
}
struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var currentMonth: Date
    let diaryDates: Set<Date>
    let fetchDataForAllDates: () -> Void  // fetchDataForAllDates를 받기 위한 클로저 추가
    
    @State private var hoveredDate: Date? = nil  // 마우스가 올라간 날짜 저장

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 1  // Sunday를 첫 번째 요일로 설정 (1: Sunday)
        return cal
    }
    
    var body: some View {
        let today = Date()  // 오늘 날짜
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        VStack {
            // 요일 헤더
            HStack(spacing: 10) {  // 요일 간격 맞춤
                ForEach(0..<7, id: \.self) { index in
                    Text(dayOfWeek(index: index))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 8)  // 좌우 패딩 추가
            
            // 날짜 표시
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 10) {  // 날짜 간격을 맞추기 위해 GridItem 수정
                // 빈 공간 채우기 (첫 번째 요일 계산 확인)
                ForEach(0..<(firstWeekday - calendar.firstWeekday), id: \.self) { index in
                    Text("")
                        .padding()
                }
                // 날짜 표시
                ForEach(1...daysInMonth.count, id: \.self) { day in
                    let currentDate = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth)!
                    
                    VStack {
                        Button(action: {
                            selectedDate = currentDate  // 버튼을 눌렀을 때 선택된 날짜를 업데이트
                        }) {
                            Text("\(day)")
                                .foregroundColor(selectedDate == currentDate ? .white : (diaryDates.contains(currentDate) ? .pink : .primary))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    // 오늘 날짜 배경 적용
                                    calendar.isDate(today, inSameDayAs: currentDate)
                                    ? Circle().fill(Color.gray).frame(width: 40, height: 40)
                                    : nil
                                )
                                .overlay(
                                    // 선택된 날짜 표시
                                    selectedDate == currentDate
                                    ? Circle().strokeBorder(Color.white, lineWidth: 3).frame(width: 40, height: 40)
                                    : nil
                                )
                        }
                        .buttonStyle(PlainButtonStyle())  // 버튼의 기본 스타일을 없애기 위해 PlainButtonStyle 사용
                        .buttonBorderShape(.roundedRectangle(radius: 0))
                    }
                    .onTapGesture {
                        selectedDate = currentDate
                    }
                    // id로 currentDate를 사용하여 중복 방지
                    .id(currentDate)
                }
            }
            .padding(.horizontal, 8)  // 좌우 패딩 추가
        }
        .onAppear {
            fetchDataForAllDates()  // 달력이 나타나면 fetchDataForAllDates 호출
        }
    }
    
    func dayOfWeek(index: Int) -> String {
        let formatter = DateFormatter()
        return formatter.shortWeekdaySymbols?[index % 7] ?? "?"
    }
}
