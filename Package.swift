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
            url: "https://github.com/keeshux/openssl-apple/releases/download/1.1.112/openssl.xcframework.zip",
            checksum: "9980b23b7f84841dd3f3fa8e9b4773b133cccff680d2ce466f2f61ba159ddeee")
    ]
)
