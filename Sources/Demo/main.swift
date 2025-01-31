

import ServiceKit
import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif


let service = Service() { req, res in
    
    if req.method == .POST {
        res.write("GOT POST: \(req.bodyString) \n")
    }
    
    
    if req.method == .GET && req.url.path == "/cow" {
        
        let task = URLSession.shared.dataTask(with: URL(string: "http://cowsay.morecode.org/say?format=text")!) { data, _, _ in
            
            if let data = data {
                let cow = String(data: data, encoding: .utf8)!
                res.write(cow)
            } else {
                res.write("error\n")
            }
            
        }
        
        task.resume()
        
    } else if req.url.path == "/" {
        
        res.write("Demo Server\n")
        
    } else {
        res.status = .notFound
        res.write("404")
    }
    
}
    
service.listen()
