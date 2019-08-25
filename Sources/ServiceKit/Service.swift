import Foundation
import NIO
import NIOHTTP1
import Logging


/**
 A typealias for the `Service` request handler. 
*/
public typealias RequestHandler = (Request, Response) -> Void


/**
 A Service is a basic HTTP server. Each incoming request will trigger the provided
 handler to fire. The handler implementation is responsible for routing, parsing, or
 any other custom behaviour then populating the `Response` as necessary.
*/
public class Service {
    

    
    /**
     Initializes a new Service with the provided request handler.
     
     - Warning: The provided handler must call `send()` on the provided `Response` in
     order to return a response to the client. Failure to do so will cause the connection
     to hang until the client times out.
     
     - Note: `send()` is called automatically when using any of the `write()` convenience methods.
     
     - parameters:
        - logger: A Logger instance. If one is not provided, a default will be created.
        - handler: The request handler.
    */
    public init(logger: Logger? = nil, handler: @escaping RequestHandler) {
        if let logger = logger {
            self.logger = logger
        } else {
            self.logger = Logger(label: "ServiceKit")
        }
        
        bootstrap(handler)
    }
    
    
    /**
     Starts the Service listening on the provided port.
    */
    public func listen(port: Int = 5000) {
        do {
            guard let bootstrap = self.bootstrap else {
                logger.error("Server not bootstrapped")
                return
            }
            
            let channel = try bootstrap.bind(host: "localhost", port: port).wait()
            logger.info("Server listening at http://localhost:\(port)")
            
            try channel.closeFuture.wait()
        } catch {
            logger.error("Error binding server")
        }
    }
    
    
    /**
     A `Logger` instance used throughout the Service.
     
     - Note: A default Logger will be created if one is not provided in `init()`
     - SeeAlso: [swift-log](https://github.com/apple/swift-log)
    */
    public let logger: Logger
    

    // MARK: - Internal
    var bootstrap: ServerBootstrap?
    func bootstrap(_ handler: @escaping RequestHandler) {
        
        self.logger.trace("Bootstrapping")
        
        let group = MultiThreadedEventLoopGroup.init(numberOfThreads: System.coreCount)
        let reuseAddrOpt = ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR)
        
        let bootstrap = ServerBootstrap(group: group)
                        .serverChannelOption(ChannelOptions.backlog, value: 256)
                        .serverChannelOption(reuseAddrOpt, value: 1)
                        .childChannelInitializer { channel in
                            
                            return channel.pipeline.configureHTTPServerPipeline(
                                withPipeliningAssistance:true,
                                withErrorHandling: true).flatMap {
                                
                                let rootHandler = RequestSession(logger: self.logger,
                                                                channel: channel,
                                                                handler: handler)
                                
                                return channel.pipeline.addHandler(rootHandler)
                            }
                        }
            
                        // gotta go fast
                        .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
                        .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 1)
                        .childChannelOption(reuseAddrOpt, value: 1)
        
        
        self.bootstrap = bootstrap
    }
    
}


// MARK: - Internal
// The root handler bridging to NIO. Assembles incoming parts from the socket into
// user-facing Request/Response objects. 
class RequestSession: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    
    let traceID: UUID
    
    let logger: Logger
    let channel: Channel
    let handler: RequestHandler
    
    // Placeholders while the requeust comes in
    var requestHeadPart: HTTPRequestHead? = nil
    var requestBodyPart: ByteBuffer? = nil
    var requestEndPart: HTTPHeaders? = nil
    
    
    init(logger: Logger, channel: Channel, handler: @escaping RequestHandler) {
        
        self.traceID = UUID()
        
        self.logger = logger
        self.channel = channel
        self.handler = handler
        
        logger.trace("\(traceID) Handler init")
    }
    
    
    deinit {
        logger.trace("\(traceID) Handler destroy")
    }
    
    
    // Handles incoming request parts, assembles them into a Request
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        
        logger.trace("\(traceID) Channel read")
        
        let part = self.unwrapInboundIn(data) as HTTPServerRequestPart
        
        switch part {
        case .head(let head):
            logger.trace("\(traceID) Request reading head")
            requestHeadPart = head
            break
        case .body(let body):
            logger.trace("\(traceID) Request reading body")
            requestBodyPart = body
            break
        case .end(let headers):
            logger.trace("\(traceID) Request reading headers, ending")
            requestEndPart = headers
            break
        }
    }
    
    
    // Abandon ship if there's an error
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        logger.error("\(traceID) Socket error: \(error)")
        context.close(promise: nil)
    }
    
    
    // Once the Request is fully assembled we create a Response and path both
    // to the user's response handler
    func channelReadComplete(context: ChannelHandlerContext) {
        
        let response = Response(session: self)
        
        guard let request = Request(session: self) else {
            logger.critical("\(traceID) Invalid incoming request, writing 500")
            
            response.status = .internalServerError
            response.write("Server error")
            response.send()
            
            return
        }

        handler(request, response)
    }
    
}
