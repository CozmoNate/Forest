# Condulet [![Build Status](https://travis-ci.com/kozlek/Condulet.svg?branch=master)](https://travis-ci.com/kozlek/Condulet)

Condulet is flexible and convenient API client construction framework built on top of `URLSession` and `URLSessionTask`. It can handle plenty of data types including multipart form data generation, sending and receiving json encoded Protobuf messages. Of course you can use your custom response handlers and data parsers with Coundulet. Condulet provides most of the features needed to build robust client for your backend services. The main purpose of it - make your job done. And my job too :) 

## Installation

### CocoaPods

```ruby
pod 'Condulet'
```


Add Protobufs supporting extensions:

```ruby
pod 'Condulet/Protobuf'
```


And don't forget to import the framework:

```swift
import Condulet
```

### Manually


Just put the files from `Core` and `Protobuf` directories somethere in your project. To use Protobuf extensions you need additionally integrate SwiftProtobuf framework into your project.


## Usage


The core class which helps to prepare network request and handle response is `ServiceTask`. `ServiceTask` also is a factory to itself. You can see all factory methods inside "ServiceTask+Request.swift". Response handling methods is defined inside "ServiceTask+Response.swift". And keep in mind, `ServiceTask` is a helper class that mostly built for subclassing. It is useful out of the box, but if you need to intercept error or provide base URL, do not hesitate to make a custom subclass. Also you can use delegation and implement  `ServiceTaskRetrofitting` protocol  

### Make a GET request expecting json response

```swift
ServiceTask()
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

ServiceTask()
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

ServiceTask()
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

let formData = MultipartFormData()

do {
    try formData.appendMediaItem(.url(name: "image", fileName: nil, mimeType: nil, url: *url*))
}
catch {
    print("\(error))
    return
}

formData.generateContentFile { (result) in

    switch result {
    case .success(let url):
        ServiceTask()
            .endpoint(.POST, "https://host.com/upload")
            .multipart(formData: .file(url), boundary: formData.boundary)
            .response(content: { (response) in
                switch response {
                case .success:
                    print("Done!")
                case .failure(let error):
                    print("Failed to upload: \(error)")
                }
            })
            .perform()

    case .failure(let error):
        print("Failed to generate form data: \(error)")
    }
}
```

Send and receive Protobuf messages:

```swift

ServiceTask()
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

// Or another version of the code above with explicitly provided types
ServiceTask()
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
