import SwiftUI
import _RealityKit_SwiftUI

struct _3DDiaryView: View {
    @Binding var diaryContent: String  // 다이어리 내용을 받는 속성
    
    var body: some View {
        RealityView { content in
            print("Diary Content: \(diaryContent)")
            
            let lineHeight: Float = 0.05  // 각 줄 간의 간격
            let charWidth: Float = 0.035  // 각 문자 간의 간격
            
            var currentXPosition: Float = 0  // X축 위치
            var currentYPosition: Float = 0  // Y축 위치 (줄 변경 시 사용)
            var maxLineWidth: Float = 0  // 한 줄에서 가장 긴 너비 추적
            var currentLineWidth: Float = 0  // 현재 줄의 너비
            
            var lineWidths: [Float] = []  // 각 줄의 너비를 저장
            
            // 첫 번째 패스: 줄 너비 계산
            for character in diaryContent {
                if character == "\n" {
                    lineWidths.append(currentLineWidth)
                    maxLineWidth = max(maxLineWidth, currentLineWidth)
                    currentLineWidth = 0  // 새로운 줄로 초기화
                } else {
                    currentLineWidth += charWidth
                }
            }
            lineWidths.append(currentLineWidth)  // 마지막 줄 너비 추가
            maxLineWidth = max(maxLineWidth, currentLineWidth)  // 마지막 줄 확인
            
            currentXPosition = -maxLineWidth / 2  // X축 시작 위치를 중앙으로 설정
            
            var lineIndex = 0  // 줄 인덱스
            
            // 두 번째 패스: 실제 배치
            for character in diaryContent {
                if character == "\n" {
                    lineIndex += 1  // 새로운 줄로 이동
                    currentXPosition = -lineWidths[lineIndex] / 2  // 새로운 줄의 X 시작 위치
                    currentYPosition -= lineHeight  // Y축을 한 줄 아래로 이동
                    continue
                }
                
                let modelName = String(character)  // 문자를 모델 이름으로 변환
                
                if let modelEntity = try? await ModelEntity(named: modelName) {
                    let clonedModel = modelEntity.clone(recursive: false)
                    // 모델을 적절한 위치에 배치 (중앙 정렬)
                    clonedModel.position = [currentXPosition, currentYPosition, 0]  // X와 Y를 각각 계산하여 배치
                    clonedModel.scale = [0.05, 0.05, 0.05]  // 모델 크기 조정
                    clonedModel.generateCollisionShapes(recursive: false)
                    clonedModel.components.set(InputTargetComponent())
                    
                    content.add(clonedModel)  // 모델을 컨텐츠에 추가
                }
                
                currentXPosition += charWidth  // 다음 문자의 X축 위치 업데이트
            }
        }
    }
}
