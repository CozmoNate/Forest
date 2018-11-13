<p align="center">
<img src="https://raw.githubusercontent.com/kozlekek/Condulet/master/logo.png">
</p>

# Condulet 

[![License](https://img.shields.io/badge/license-MIT-ff69b4.svg)](https://github.com/kozlek/Condulet/raw/master/LICENSE)
[![Language](https://img.shields.io/badge/swift-4.2-orange.svg)](https://swift.org/blog/swift-4-2-released/)
[![Version](https://img.shields.io/cocoapods/v/Condulet.svg)](https://cocoapods.org/pods/Condulet)
[![Build Status](https://travis-ci.com/kozlekek/Condulet.svg?branch=master)](https://travis-ci.com/kozlekek/Condulet)
[![Coverage Status](https://coveralls.io/repos/github/kozlekek/Condulet/badge.svg?branch=master)](https://coveralls.io/github/kozlekek/Condulet?branch=master)

Condulet is flexible and extensible REST API client construction framework built on top of `URLSession` and `URLSessionTask`. It already inculdes network object mappers from JSON to the most commonly used data types. Because of it simple data encoding/decoding approach and extensible architecture you can easily add your custom network object mappers. Condulet provides all of the features needed to build robust client for your backend services. 

You could ask why not to get any other proven networking framework? Sure, you’ll get one best suitable for your needs and style preference, but it's always good to have an options. Following is the list of features I wanted from higher level networking layer and imlemented in Condulet:

* Promise like style request building without needing to make any enums or classes describing endponts 
* Promise like style body configuration, simple network objects encoding  
* Promise like style response handling and simple network objects mapping 
* Handle response in the same place as the request and body configuration 
* Transparent and completely customizable response interception and rewind/retry, allowing async handling. Mainly to map errors and catch expired token in case of OAuth-like secured request 
* Extensibility. Easily add custom response mappers and body data encoders using closures, or protocols, or subclassing whichever will be more convenient for specific need. Use this with default framework’s classes or extend them or subclass, but it should be easy. 
* Download and keep files where I need them
* Deserialization of JSON body. Map JSON to array, or dictionary, or by using objects conforming to `Decodable` protocol 
* Serialization and deserialization of Protobufs messages (gRPC over HTTP)
* Multipart form data support as a bonus 

## Installation

### CocoaPods

```ruby
pod 'Condulet'
```


Add Protobufs supporting extensions:

```ruby
pod 'Condulet/Protobuf'
```

To use reachability service:

```ruby
pod 'Condulet/Reachability'
```

And don't forget to import the framework:

```swift
import Condulet
```

### Manually


Just put the files from `Core` and `Protobuf` directories somethere in your project. To use Protobuf extensions you need additionally integrate SwiftProtobuf framework into your project.


## Usage


The core class which handles network task is `ServiceTask`. `ServiceTaskBuilder` provides factory methods helping to create and configure instance of `ServiceTask`. If you need more control over the process of making request and handling the response, you can use delegation and implement  `ServiceTaskRetrofitting` protocol and modify task behavior via retrofitter. Also you can subclass `ServiceTask`, it is built for that.  

### Make a GET request expecting json response

```swift
ServiceTaskBuilder()
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

ServiceTaskBuilder()
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

ServiceTaskBuilder()
    .headers(["Authorization": "Bearer \(token)"])
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


Upload multipart form data encoded content:

```swift

// Create new form data builder
var formDataBuilder = FormDataBuilder()

do {

    // Filename and MIME type will be obtained automatically from URL. It can be provided explicitly too
    try formDataBuilder.append(.file(name: "image", url: *url*))
    
    // Generate form data in memory. It also can be written directly to disk or stream using encode(to:) method 
    let formData = try formDataBuilder.encode()
    
    ServiceTaskBuilder()
            .endpoint(.POST, "https://host.com/upload")
            .body(data: formData, contentType: formDataBuilder.contentType)
            .response(content: { (response) in
                switch response {
                case .success:
                    print("Done!")
                case .failure(let error):
                    print("Failed to upload: \(error)")
                }
            })
            .perform()
}
catch {
    print("\(error))
    return
}
```

Send and receive Protobuf messages (gRPC over HTTP):

```swift

ServiceTaskBuilder()
    .endpoint(.POST, "https://host.com")
    // Create and configure request message in place
    .body { (message: inout Google_Protobuf_StringValue) in
        message.value = "something"
    }
    // Expecting Google_Protobuf_Empty message response
    .proto{ (message: Google_Protobuf_Empty, response) in
        print("Done!")
    }
    .error { (error, response) in
        print("Error occured: \(error)")
    }
    .perform()

// Or another version of the code above with explicitly provided types
ServiceTaskBuilder()
    .endpoint(.POST, "https://host.com")
    // Create and configure request message in place
    .body(proto: Google_Protobuf_SourceContext.self) { (message) in
        message.fileName = "file.name"
    }
    // Expecting Google_Protobuf_Empty message response
    .response(proto: Google_Protobuf_Empty.self) { (response) in
        switch response {
        case .success(let message):
            print("Done!")
        case .failure(let error):
            print("Error occured: \(error)")
        }
    }
    .perform()
```

## Author


Natan Zalkin natan.zalkin@me.com

## License


Condulet is available under the MIT license. See the LICENSE file for more info.
