// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OscarsTracker",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "OscarsTracker",
            targets: ["OscarsTracker"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "2.0.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "OscarsTracker",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "Kingfisher", package: "Kingfisher"),
            ],
            path: "OscarsTracker"
        ),
    ]
)
