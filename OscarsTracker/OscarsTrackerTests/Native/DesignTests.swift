import CoreImage
import Foundation
import SwiftUI
import Testing
@testable import OscarsTracker

@MainActor
@Suite("Ambient backdrop")
struct AmbientBackgroundTests {
    @Test func picksUpToFourPostersSpreadThroughTheList() {
        let urls = (1...10).map { "https://example.com/\($0).jpg" }
        let picked = AmbientBackground.pick(urls)
        #expect(picked.count == 4)
        #expect(picked.first == urls[0])
        #expect(Set(picked).count == 4)
    }

    @Test func dropsDuplicatesAndBlanks() {
        #expect(AmbientBackground.pick(["a", "a", "", "b", "c"]) == ["a", "b", "c"])
        #expect(AmbientBackground.pick([]).isEmpty)
    }

    @Test func keepsTheCornersStillAndDriftsTheRestALittle() {
        for time in stride(from: 0.0, through: 60, by: 7.5) {
            let points = AmbientBackground.points(at: time)
            #expect(points.count == 9)
            #expect(points[0] == [0, 0] && points[2] == [1, 0] && points[6] == [0, 1] && points[8] == [1, 1])
            for point in points {
                #expect(abs(point.x - 0.5) <= 0.56 && abs(point.y - 0.5) <= 0.56)
            }
            // Edge midpoints stay on their edges.
            #expect(points[1].y == 0 && points[7].y == 1 && points[3].x == 0 && points[5].x == 1)
        }
        #expect(AmbientBackground.points(at: 0) != AmbientBackground.points(at: 15))
    }

    @Test func spreadsThePaletteOverTheGround() {
        let colors = AmbientBackground.colors([.red, .blue])
        #expect(colors.count == 9)
        #expect(colors[0] == .red && colors[8] == .blue && colors[4] == .red && colors[2] == .blue)
        #expect(colors[1] == .ground && colors[7] == .ground)
    }
}

@Suite("Poster palette")
struct PosterPaletteTests {
    @Test func findsTheVividColourInAPoster() throws {
        // A poster that's mostly near-black with a red block.
        let dark = CIImage(color: CIColor(red: 0.05, green: 0.05, blue: 0.05)).cropped(to: CGRect(x: 0, y: 0, width: 64, height: 64))
        let red = CIImage(color: CIColor(red: 0.8, green: 0.1, blue: 0.1)).cropped(to: CGRect(x: 0, y: 64, width: 64, height: 32))
        let clusters = try #require(PosterPalette.clusters(in: red.composited(over: dark), context: CIContext()))
        #expect(clusters.count == 3)
        let vivid = try #require(clusters.max { $0.vividness < $1.vividness })
        #expect(vivid.red > 0.5 && vivid.green < 0.3 && vivid.blue < 0.3)
    }

    @Test func ranksGreyBelowColour() {
        #expect(PosterPalette.Cluster(red: 0.5, green: 0.5, blue: 0.5).vividness == 0)
        #expect(PosterPalette.Cluster(red: 0.8, green: 0.2, blue: 0.2).vividness > 0.5)
    }
}
