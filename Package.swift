// swift-tools-version:5.2

import PackageDescription

let package = Package(
  name: "KinoTochkaApi",
  platforms: [
    .macOS(.v10_12),
    .iOS(.v12),
    .tvOS(.v12)
  ],
  products: [
    .library(name: "KinoTochkaApi", targets: ["KinoTochkaApi"])
  ],
  dependencies: [
    //.package(path: "../SimpleHttpClient"),
    .package(url: "https://github.com/shvets/SimpleHttpClient", from: "1.0.8"),
    .package(url: "https://github.com/scinfu/SwiftSoup", from: "2.3.2"),
    .package(url: "https://github.com/JohnSundell/Codextended", from: "0.3.0"),
    //.package(url: "https://github.com/shvets/DiskStorage", from: "1.0.1")
  ],
  targets: [
    .target(
      name: "KinoTochkaApi",
      dependencies: [
        "SimpleHttpClient",
        "SwiftSoup",
        "Codextended"
        //"DiskStorage"
      ]),
    .testTarget(
      name: "KinoTochkaApiTests",
      dependencies: [
        "KinoTochkaApi"
      ]),
  ]
)
