// swift-tools-version:5.9

import PackageDescription

let package = Package(
  name: "KinoTochkaApi",
  platforms: [
    .macOS(.v14),
    .iOS(.v17),
    .tvOS(.v17)
  ],
  products: [
    .library(name: "KinoTochkaApi", targets: ["KinoTochkaApi"])
  ],
  dependencies: [
    //.package(name: "SimpleHttpClient", path: "../SimpleHttpClient"),
    .package(url: "https://github.com/shvets/SimpleHttpClient", from: "1.0.10"),
    .package(url: "https://github.com/scinfu/SwiftSoup", from: "2.8.8"),
    .package(url: "https://github.com/JohnSundell/Codextended", from: "0.3.0"),
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
