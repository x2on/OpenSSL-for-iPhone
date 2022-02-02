// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "openssl-apple",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "openssl-apple",
            targets: ["openssl"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .binaryTarget(
            name: "openssl",
            url: "https://github.com/keeshux/openssl-apple/releases/download/1.1.11300/openssl.xcframework.zip",
            checksum: "242cfecf41d42013037698fbfc3237830afc4546eb741d5490b3e3c49a996f81")
    ]
)
