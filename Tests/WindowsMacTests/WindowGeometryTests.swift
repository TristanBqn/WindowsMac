import CoreGraphics
import Testing
@testable import WindowsMac

@Test func leftHalfUsesHalfVisibleWidth() {
    let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let result = WindowGeometry.frame(for: .leftHalf, in: screen)

    #expect(result == CGRect(x: 0, y: 0, width: 960, height: 1080))
}

@Test func rightHalfStartsAtMidpoint() {
    let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let result = WindowGeometry.frame(for: .rightHalf, in: screen)

    #expect(result == CGRect(x: 960, y: 0, width: 960, height: 1080))
}

@Test func successiveUpFromLeftCreatesTopLeft() {
    #expect(WindowGeometry.nextState(from: .leftHalf, direction: .up) == .topLeft)
}

@Test func successiveUpFromTopMaximizes() {
    #expect(WindowGeometry.nextState(from: .topHalf, direction: .up) == .maximized)
}
