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
