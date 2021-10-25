// swift-tools-version:5.5
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
            url: "https://github.com/keeshux/openssl-apple/releases/download/openssl-1.1.1l/openssl.xcframework.zip",
            checksum: "18628fddadcac81c96e5824d62991b93172f58c7539cebb4ddba4df52b99aade")
    ]
)
