import Foundation
import NIO
import NIOHTTP1
import Logging


/**
 An HTTP response for an incoming request.
*/
public class Response {
    
    /**
     Headers to include with the response.
    */
    public var headers: [(String,String)] = [
        ("Access-Control-Allow-Origin", "*")
    ]
    
    
    /**
     The HTTP status to return with the response.
     
     - Note: Defaults to 200 OK
    */
    public var status: HTTPResponseStatus = .ok
    
    
    /**
     The response body.
    */
    public var body: Data = Data()

    
    /**
     Sends the response back to the client. This will write the Response to the wire
     in it's current state.
     
     - Note: You do not need to call this function directly if using one of the
     `write()` functions to populate the response body.
    */
    public func send() {
        if !locked {
            lockAndSend()
        }
    }
    
    
    // MARK: - Internal
    // Internal back-reference to parent session
    weak var session: RequestSession? = nil
    private var locked: Bool = false
    
    init(session: RequestSession) {
        self.session = session
    }
    
}


// MARK: - Convenience
extension Response {

    /**
     Writes a text string to the response body and sends it.
     
     - Note: This function will `send()` the response.
     
     - parameter text: the response string
    */
    public func write(_ text: String) {
        guard let session = self.session, !locked else {
            return
        }
        
        if let textData = text.data(using: .utf8) {
            body = textData
        } else {
            session.logger.error("\(session.traceID) Could not convert message to data buffer")
        }
        send()
    }
    

    /**
     Encodes the given object as a JSON string, writes it to the response
     body, and sends it.
     
     - Note: This function will `send()` the response.
     
     - parameter json: The `Codable` to be encoded to JSON
    */
    public func write<T:Codable>(json: T) {
        
        guard let session = self.session, !locked else {
            return
        }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // be polite
        do {
            let encodedData = try encoder.encode(json)
            if let encodedString = String(data: encodedData, encoding: .utf8) {
                self.write(encodedString)
            } else {
                session.logger.debug("\(session.traceID) JSON string encoding failed")
            }
            
        }
        catch {
            session.logger.debug("\(session.traceID) JSON encoding failed")
        }
        
    }
    
}


// MARK: - Network
extension Response {
    
    /*
     Locks the Response and writes it back to the channel/network
    */
    func lockAndSend() {
    
        guard let session = self.session, !locked else {
            return
        }
        
        // Lock the response
        locked = true
        
        // Write the header
        let head = HTTPResponseHead(version: .init(major:1, minor:1),
                                    status: status,
                                    headers: HTTPHeaders(headers))
        let headPart = HTTPServerResponsePart.head(head)
        _ = session.channel.writeAndFlush(headPart).map {
            session.logger.trace("\(session.traceID) Response wrote header")
        }
        
        
        // Write the body
        var buffer = session.channel.allocator.buffer(capacity: body.count)
        buffer.writeBytes(body)
        
        let bodyPart = HTTPServerResponsePart.body(.byteBuffer(buffer))
        
        _ = session.channel.writeAndFlush(bodyPart).map {
            session.logger.trace("\(session.traceID) Response wrote body")
            
            // End the message and close the channel
            _ = session.channel.writeAndFlush(HTTPServerResponsePart.end(nil)).map {
                session.logger.trace("\(session.traceID) Response wrote end, closing")
                _ = session.channel.close()
            }
        }
    }
}

