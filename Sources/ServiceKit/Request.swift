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
    
    init?(session: RequestSession) {
        guard let head = session.requestHeadPart else {
            return nil
        }
        
        self.head = head
        self.bodyBuffer = session.requestBodyPart
        self.end = session.requestEndPart
    }
}


// MARK: - Public
extension Request {
    
    /**
     The URI of the incoming request, as a URL for convenience
    */
    public var url: URL {
        get {
            // Might need to do swiftlint:disable force_unwrapping here eventually
            return URL(string: head.uri)!
        }
    }
    
    
    /**
     The HTTP method of the incoming request (GET, POST, etc)
    */
    public var method: HTTPMethod {
        get {
            return head.method
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
    
    /**
     The body of the incoming request, as a String for convencience.
    */
    public var bodyString: String {
        get {
            return String(data: body, encoding: .utf8) ?? ""
        }
    }
}
