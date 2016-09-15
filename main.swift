import Glibc
import Dispatch

let Q = DispatchQueue.main

func setupListenSocket(port p: Int) -> Int32 {
  var address = Glibc.sockaddr_in()
  address.sin_addr = in_addr(s_addr: 0)
  address.sin_port = in_port_t(p).bigEndian

  // MANUAL ACCEPT
  let lfd = Glibc.socket(Glibc.AF_INET, Int32(Glibc.SOCK_STREAM.rawValue), 0)

  do { // SO_REUSEADDR
    var buf    = Int32(1)
    let buflen = socklen_t(MemoryLayout<Int32>.stride)
    _ = Glibc.setsockopt(lfd, Glibc.SOL_SOCKET, Glibc.SO_REUSEADDR,
                        &buf, buflen)
  }

  do { // bind
    _ = withUnsafePointer(to: &address) { ptr in
      ptr.withMemoryRebound(to: Glibc.sockaddr.self, capacity: 1) {
        bptr in
        Glibc.bind(lfd, UnsafePointer(bptr), 
                   socklen_t(MemoryLayout<sockaddr_in>.stride))
      }
    }
  }
  
  return lfd
}

func doAccept(socket lfd: Int32) -> Int32 {
  var baddr    = Glibc.sockaddr_in()
  var baddrlen = socklen_t(MemoryLayout<sockaddr_in>.stride)

  let newFD = withUnsafeMutablePointer(to: &baddr) { ptr -> Int32 in
    return ptr.withMemoryRebound(to: Glibc.sockaddr.self, capacity: 1) {
      bptr -> Int32 in
      return Glibc.accept(lfd, bptr, &baddrlen);// buflenptr)
    }
  }
  print("  FD: \(newFD)")
  return newFD
}

var channel : DispatchIO? = nil // just a demo

let lfd          = setupListenSocket(port: 1337)
let listenSource = DispatchSource.makeReadSource(fileDescriptor: lfd, queue: Q)

listenSource.setEventHandler {
  let newFD = doAccept(socket: lfd)
 
  channel = DispatchIO(type: DispatchIO.StreamType.stream,
                       fileDescriptor: newFD, 
                       queue: Q,
                       cleanupHandler: { err in print("Cleanup: \(err)") })
  channel!.setLimit(lowWater: 1)

  channel!.read(offset: 0, length: 1000, queue: Q) {
    done, pdata, error in
    
    print("  CHANNEL READ: \(done) \(pdata) \(error)")
  }
}
listenSource.resume()

_ = Glibc.listen(lfd, Int32(2))

print("listening ...")
dispatchMain() // never returns
