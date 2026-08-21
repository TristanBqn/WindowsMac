import CoreGraphics
import Foundation
import Testing
@testable import WindowsMacCore

@Test func halvesUseVisibleFrame() {
    let screen = CGRect(x: 100, y: 50, width: 1920, height: 1080)

    #expect(WindowGeometry.frame(for: .leftHalf, in: screen) == CGRect(x: 100, y: 50, width: 960, height: 1080))
    #expect(WindowGeometry.frame(for: .rightHalf, in: screen) == CGRect(x: 1060, y: 50, width: 960, height: 1080))
    #expect(WindowGeometry.frame(for: .topHalf, in: screen) == CGRect(x: 100, y: 590, width: 1920, height: 540))
    #expect(WindowGeometry.frame(for: .bottomHalf, in: screen) == CGRect(x: 100, y: 50, width: 1920, height: 540))
}

@Test func quartersUseVisibleFrame() {
    let screen = CGRect(x: -1920, y: 24, width: 1920, height: 1056)

    #expect(WindowGeometry.frame(for: .topLeft, in: screen) == CGRect(x: -1920, y: 552, width: 960, height: 528))
    #expect(WindowGeometry.frame(for: .bottomRight, in: screen) == CGRect(x: -960, y: 24, width: 960, height: 528))
}

@Test func successiveDirectionsProduceRequestedStates() {
    #expect(WindowGeometry.nextState(from: .leftHalf, direction: .up) == .topLeft)
    #expect(WindowGeometry.nextState(from: .leftHalf, direction: .down) == .bottomLeft)
    #expect(WindowGeometry.nextState(from: .rightHalf, direction: .up) == .topRight)
    #expect(WindowGeometry.nextState(from: .rightHalf, direction: .down) == .bottomRight)
    #expect(WindowGeometry.nextState(from: .topHalf, direction: .up) == .maximized)
}

@Test func stateRecognitionToleratesWindowBorderDifferences() {
    let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let almostLeft = CGRect(x: 2, y: 1, width: 956, height: 1077)

    #expect(WindowGeometry.matchingState(for: almostLeft, in: screen) == .leftHalf)
}

@Test func unrelatedFrameIsNotMistakenForSnapState() {
    let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let normalWindow = CGRect(x: 240, y: 190, width: 1000, height: 700)

    #expect(WindowGeometry.matchingState(for: normalWindow, in: screen) == nil)
}

@Test func coordinateConversionRoundTripsAcrossDisplays() {
    let primary = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    let appKitRect = CGRect(x: -1600, y: -700, width: 800, height: 600)

    let axRect = CoordinateConverter.appKitToAccessibility(appKitRect, primaryScreenFrame: primary)
    #expect(axRect == CGRect(x: -1600, y: 1180, width: 800, height: 600))
    #expect(CoordinateConverter.accessibilityToAppKit(axRect, primaryScreenFrame: primary) == appKitRect)
}

@Test func commandPayloadDecodes() throws {
    let data = Data(#"{"command":"snap","direction":"left"}"#.utf8)
    let command = try JSONDecoder().decode(WindowsMacCommand.self, from: data)

    #expect(command == WindowsMacCommand(command: .snap, direction: .left))
}
