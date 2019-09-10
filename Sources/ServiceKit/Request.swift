import Foundation
import NIO
import NIOHTTP1
import Logging


/**
 An incoming HTTP request.
*/
public class Request {
    
    // MARK: - Internal
    let head: HTTPRequestHead
    var bodyBuffer: ByteBuffer?
    var end: HTTPHeaders?
    let unwrappedURL: URL
    
    init?(session: RequestSession) {
        guard let head = session.requestHeadPart, let url = URL(string: head.uri) else {
            return nil
        }
        
        self.head = head
        self.bodyBuffer = session.requestBodyPart
        self.end = session.requestEndPart
        self.unwrappedURL = url
    }
}


// MARK: Request
extension Request {
    
    /**
     The URI of the incoming request, as a URL for convenience
    */
    public var url: URL {
        get {
            return unwrappedURL
        }
    }
    
    
    /**
     The HTTP method of the incoming request (GET, POST, etc)

     - SeeAlso: [HTTPMethod](https://apple.github.io/swift-nio/docs/current/NIOHTTP1/Enums/HTTPMethod.html)
    */
    public var method: HTTPMethod {
        get {
            return head.method
        }
    }
    

    /**
     The content type of the incoming request.

     - Note: Defaults to `application/octet-stream` if missing 
    */
    public var contentType: String {
        get {
            return head.headers["Content-Type"].first ?? "application/octet-stream"
        }
    }
    

    /**
     The HTTP headers of the incoming request. 

     - SeeAlso: [HTTPHeaders](https://apple.github.io/swift-nio/docs/current/NIOHTTP1/Structs/HTTPHeaders.html)
    */
    public var headers: HTTPHeaders {
        get {
            return head.headers
        }
    }


    /**
     The body of the incoming request.
    */
    public var body: Data {
        get {
            if let buffer = bodyBuffer {
                return Data(buffer.readableBytesView)
            }
            return Data()
        }
    }

}


// MARK: - Convenience
extension Request {

    /**
     The body of the incoming request, as a String for convencience.
    */
    public var bodyString: String {
        get {
            return String(data: body, encoding: .utf8) ?? ""
        }
    }


    /**
     Attempts to decode the body of the incoming request from 
     JSON into the specified `Codable`. 

     - parameter as: The type to decode into.
    */
    public func json<T:Codable>(as: T) throws -> T {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: body) 
    }
}
