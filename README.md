# Condulet

Condulet is a simple wrapper built on top of URLSession and URLSessionTask. When you need to simply send request, receive data, parse value and return to completion block - this framework is for you. Condulet also flexible and extensible. You can add your custom response handlers and data parsers. Condulet provide most of the features you'll need in your day-by-day work, without stressing you with overcomplicated abstractions. Thats the main purpose of it - help to make your job done.

## Installation

### CocoaPods

```ruby
pod 'Condulet', :git => 'https://github.com/kozlek/Condulet.git'
```

Add Protobufs supporting extensions:

```ruby
pod 'Condulet/Protobuf', :git => 'https://github.com/kozlek/Condulet.git'
```

And don't forget to import the framework:

```swift
import Condulet
```

### Manually

Just put the files from `Core` and `Protobuf` directories somethere in your project. To use Protobuf extensions you need additionally integrate SwiftProtobuf framework into your project.


## Usage

### Make a GET request expecting json response

```swift
TaskBuilder()
    .url("https://host.com/path/to/endpoint")
    .method(.GET)
    .query(["param": value])
    // Expecting valid JSON response
    .json { (object, response) in
        print("JSON response received: \(object)")
    }
    .error { (error, response) in
        print("Error occured: \(error)")
    }
    .perform()
```

### Sending and receiving data

Send and receive data using objects conforming to Codable protocol:

```swift

struct NameRequest: Encodable {
    let name: String
}

struct NameResponse: Decodable {
    let isValid: Bool
}

TaskBuilder()
    // Set base url and HTTP method
    .endpoint(.POST, "https://host.com")
    // Add path to resource
    .path("/path/to/resource")
    // Serialize our Codable struct and set body
    .body(encodable: NameRequest("some"))
    // Expect response with the object of 'NameResponse' type
    .decodable { (object: NameResponse, response) in
        print("Name valid: \(object.isValid)")
    }
    // Otherwise will fail with error
    .error { (error, response) in
        print("Error occured: \(error)")
    }
    .perform()
```

Just download some file:

```swift

TaskBuilder()
    .headers(["Authentication": "Bearer \(token)"])
    .method(.PUT)
    .url("https://host.com/file/12345")
    .body(text: "123456789")
    .file { (url, response) in
        print("Downloaded: \(url)")
    }
    .error { (error, response) in
        print("Error occured: \(error)")
    }
    .download()
```

## Author

Natan Zalkin, natan.zalkin@me.com

## License

Condulet is available under the MIT license. See the LICENSE file for more info.
