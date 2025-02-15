// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "JLog",
                      platforms: [
                          .iOS(.v17),
                          .macOS(.v14),
                          .tvOS(.v17),
                          .watchOS(.v9),
                      ],
                      products: [
                          // Products define the executables and libraries a package produces, and make them visible to other packages.
                          .library(name: "JLog",
                                   targets: ["JLog"]),
                      ],
                      dependencies: [
                          // Dependencies declare other packages that this package depends on.
                          // .package(url: /* package url */, from: "1.0.0"),
                          .package(url: "https://github.com/Adorkable/swift-log-format-and-pipe", from: "0.1.1"),
                          .package(url: "https://github.com/apple/swift-log.git", from: "1.2.0"),
                          .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.2"),
                      ],
                      targets: [
                          // Targets are the basic building blocks of a package. A target can define a module or a test suite.
                          // Targets can depend on other targets in this package, and on products in packages this package depends on.
                          .target(name: "JLog",
                                  dependencies: [.product(name: "Logging", package: "swift-log"),
                                                 .product(name: "LoggingFormatAndPipe", package: "swift-log-format-and-pipe")]),

                          .testTarget(name: "JLogTests",
                                      dependencies: ["JLog"]),

                          .executableTarget(name: "JLogExample",
                                            dependencies: ["JLog",
                                                           .product(name: "ArgumentParser", package: "swift-argument-parser")]),
                      ])
