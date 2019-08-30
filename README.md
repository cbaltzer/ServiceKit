# ServiceKit

![Mac build status](https://github.com/cbaltzer/ServiceKit/workflows/Mac/badge.svg)
![Linux build status](https://github.com/cbaltzer/ServiceKit/workflows/Linux/badge.svg)

*** 

ServiceKit is a minimalist foundation for building web services in Swift, micro or otherwise. 

A super simple example:

```swift
import ServiceKit

let service = Service() { req, res in
  res.write("Sup, nerds?")
}

service.listen()
```


# Getting Started 

Getting up and running is pretty quick. You can use this repo as a reference. Check out the [Demo](https://github.com/cbaltzer/ServiceKit/tree/master/Sources/Demo) folder and [Package.swift](https://github.com/cbaltzer/ServiceKit/tree/master/Package.swift). 

To see it in action, just clone this repo and do:

```
swift run 
```


## Basic Setup

To get started on your own, make a folder for your project and start a new [Swift Package](https://swift.org/package-manager/): 

```bash 
swift package init --name DemoService --type executable
```

Then, update your `Package.swift` file. If you're new to Swift this is the main manifest file
for your project. Similar to `package.json` in Node, for example.

```swift 
// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "DemoService",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // This is the magic line. 
        .package(url: "https://github.com/cbaltzer/ServiceKit", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "DemoService",
            dependencies: ["ServiceKit"]), // Tell the linker to actually connect our dependency
        .testTarget(
            name: "DemoServiceTests",
            dependencies: ["DemoService"]),
    ]
)
```

The initializer for your package should have provided a `main.swift` file. Fill it out with 
a Hello World sample to make sure everything works:

```swift
import ServiceKit

let demo = Service() { req, res in
  res.write("Hi, it works!")
}

demo.listen()
```

Now finally to launch your new service:

```
swift run 
```

Check it out at [http://localhost:5000/](http://localhost:5000/)



## Environment Setup

### Xcode (Mac)

This is the way to go if you're on a Mac. Installing Xcode from the Mac App Store will include
the Swift toolchains. 

Editing is also easiest with Xcode:

```
swift package generate-xcodeproj
```

### VSCode (Mac, Linux, Windows)

Getting a Swift dev environment set up on any platform is made pretty easy with the [Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) 
extension. This will launch a [Docker](https://www.docker.com/) container with the specified environment, including toolchains and other extensions.

Check out the [.devcontainer](https://github.com/cbaltzer/ServiceKit/tree/master/.devcontainer) folder for reference.


# Deploying

Deploying is easiest with Docker. Check out the [Dockerfile](https://github.com/cbaltzer/ServiceKit/tree/master/Dockerfile) 
for a basic example of how the demo service is bundled. 


