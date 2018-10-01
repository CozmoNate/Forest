# Condulet

Condulet is a simple wrapper built on top of URLSession and URLSessionTask. When you need to simply send request, receive data, parse value and return to completion block - this framework is for you. Condulet also flexible and extensible. You can add your custom response handlers and data parsers. Condulet provide most of the features you'll need in your day-by-day work, without stressing you with overcomplicated abstractions. That the main purpose of it - help to make your job done.

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
    .body(codable: NameRequest("some"))
    // Expect response with the object of 'NameResponse' type
    .codable { (object: NameResponse, response) in
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
        // Remove temp file
        try? FileManager.default.removeItem(at: url)
    }
    .error { (error, response) in
        print("Error occured: \(error)")
    }
    // When download destination not provided, content will be downloaded and saved to temp file
    .download()
```

Send and receive Protobuf messages:

```swift

TaskBuilder()
    .endpoint(.POST, "https://host.com")
    // Create and configure request message in place
    .body { (message: inout Google_Protobuf_SourceContext) in
        message.fileName = "file.name"
    }
    // Expecting Google_Protobuf_Empty message response
    .proto{ (message: Google_Protobuf_Empty, response) in
        print("Done!")
    }
    .error { (error, response) in
        print("Error occured: \(error)")
    }
    .perform()
```

## Author

Natan Zalkin, natan.zalkin@me.com

## License

Condulet is available under the MIT license. See the LICENSE file for more info.
