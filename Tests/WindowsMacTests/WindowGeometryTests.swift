import CoreGraphics
import Foundation
import XCTest
@testable import WindowsMacCore

final class WindowGeometryTests: XCTestCase {
    func testHalvesUseVisibleFrame() {
        let screen = CGRect(x: 100, y: 50, width: 1920, height: 1080)
        XCTAssertEqual(WindowGeometry.frame(for: .leftHalf, in: screen), CGRect(x: 100, y: 50, width: 960, height: 1080))
        XCTAssertEqual(WindowGeometry.frame(for: .rightHalf, in: screen), CGRect(x: 1060, y: 50, width: 960, height: 1080))
        XCTAssertEqual(WindowGeometry.frame(for: .topHalf, in: screen), CGRect(x: 100, y: 590, width: 1920, height: 540))
        XCTAssertEqual(WindowGeometry.frame(for: .bottomHalf, in: screen), CGRect(x: 100, y: 50, width: 1920, height: 540))
    }

    func testQuartersUseVisibleFrame() {
        let screen = CGRect(x: -1920, y: 24, width: 1920, height: 1056)
        XCTAssertEqual(WindowGeometry.frame(for: .topLeft, in: screen), CGRect(x: -1920, y: 552, width: 960, height: 528))
        XCTAssertEqual(WindowGeometry.frame(for: .bottomRight, in: screen), CGRect(x: -960, y: 24, width: 960, height: 528))
    }

    func testSuccessiveDirectionsProduceRequestedStates() {
        XCTAssertEqual(WindowGeometry.nextState(from: .leftHalf, direction: .up), .topLeft)
        XCTAssertEqual(WindowGeometry.nextState(from: .leftHalf, direction: .down), .bottomLeft)
        XCTAssertEqual(WindowGeometry.nextState(from: .rightHalf, direction: .up), .topRight)
        XCTAssertEqual(WindowGeometry.nextState(from: .rightHalf, direction: .down), .bottomRight)
        XCTAssertEqual(WindowGeometry.nextState(from: .topHalf, direction: .up), .maximized)
    }

    func testStateRecognitionToleratesWindowBorderDifferences() {
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let almostLeft = CGRect(x: 2, y: 1, width: 956, height: 1077)
        XCTAssertEqual(WindowGeometry.matchingState(for: almostLeft, in: screen), .leftHalf)
    }

    func testUnrelatedFrameIsNotMistakenForSnapState() {
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let normalWindow = CGRect(x: 240, y: 190, width: 1000, height: 700)
        XCTAssertNil(WindowGeometry.matchingState(for: normalWindow, in: screen))
    }

    func testCoordinateConversionRoundTripsAcrossDisplays() {
        let primary = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let appKitRect = CGRect(x: -1600, y: -700, width: 800, height: 600)
        let axRect = CoordinateConverter.appKitToAccessibility(appKitRect, primaryScreenFrame: primary)
        XCTAssertEqual(axRect, CGRect(x: -1600, y: 1180, width: 800, height: 600))
        XCTAssertEqual(CoordinateConverter.accessibilityToAppKit(axRect, primaryScreenFrame: primary), appKitRect)
    }

    func testCommandPayloadDecodes() throws {
        let data = Data(#"{"command":"snap","direction":"left"}"#.utf8)
        let command = try JSONDecoder().decode(WindowsMacCommand.self, from: data)
        XCTAssertEqual(command, WindowsMacCommand(command: .snap, direction: .left))
    }
}
