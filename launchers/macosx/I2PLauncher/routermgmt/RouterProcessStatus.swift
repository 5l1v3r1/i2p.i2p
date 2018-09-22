//
//  RouterProcessStatus.swift
//  I2PLauncher
//
//  Created by Mikal Villa on 18/09/2018.
//  Copyright © 2018 The I2P Project. All rights reserved.
//

import Foundation
import AppKit

@objc class RouterProcessStatus : NSObject {
  
  /**
   *
   * Why the functions bellow? Because the Objective-C bridge is limited, it can't do Swift "static's" over it.
   *
   **/
 
  @objc func setRouterStatus(_ isRunning: Bool = false) {
    RouterProcessStatus.isRouterRunning = isRunning
  }
  
  @objc func setRouterRanByUs(_ ranByUs: Bool = false) {
    RouterProcessStatus.isRouterChildProcess = ranByUs
  }
  
  @objc func getRouterIsRunning() -> Bool {
    return RouterProcessStatus.isRouterRunning
  }
  
  @objc func getJavaHome() -> String {
    return RouterProcessStatus.knownJavaBinPath!
  }
  
  @objc func triggerEvent(en: String, details: String? = nil) {
    RouterManager.shared().eventManager.trigger(eventName: en, information: details)
  }
}

extension RouterProcessStatus {
  static var isRouterRunning : Bool = false
  static var isRouterChildProcess : Bool = false
  static var routerVersion : String? = Optional.none
  static var routerUptime : String? = Optional.none{
    //Called before the change
    willSet(newValue){
      print("RouterProcessStatus.routerUptime will change from ", (self.routerUptime ?? "nil"), " to "+(newValue ?? "nil"))
    }
    
    //Called after the change
    didSet{
      print("RouterProcessStatus.routerUptime did change to "+self.routerUptime!)
    }
  }
  static var routerStartedAt : Date? = Optional.none
  static var knownJavaBinPath : String? = Optional.none
  static var i2pDirectoryPath : String = NSHomeDirectory() + "/Library/I2P"
  
  static var knownRouterSubTaskRef : I2PSubprocess? = Optional.none
  
}




extension RouterProcessStatus {
  static func checkTcpPortForListen(port: in_port_t) -> (Bool, descr: String){
    
    let socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0)
    if socketFileDescriptor == -1 {
      return (false, "SocketCreationFailed, \(descriptionOfLastError())")
    }
    
    var addr = sockaddr_in()
    let sizeOfSockkAddr = MemoryLayout<sockaddr_in>.size
    addr.sin_len = __uint8_t(sizeOfSockkAddr)
    addr.sin_family = sa_family_t(AF_INET)
    addr.sin_port = Int(OSHostByteOrder()) == OSLittleEndian ? _OSSwapInt16(port) : port
    addr.sin_addr = in_addr(s_addr: inet_addr("0.0.0.0"))
    addr.sin_zero = (0, 0, 0, 0, 0, 0, 0, 0)
    var bind_addr = sockaddr()
    memcpy(&bind_addr, &addr, Int(sizeOfSockkAddr))
    
    if Darwin.bind(socketFileDescriptor, &bind_addr, socklen_t(sizeOfSockkAddr)) == -1 {
      let details = descriptionOfLastError()
      release(socket: socketFileDescriptor)
      return (false, "\(port), BindFailed, \(details)")
    }
    if listen(socketFileDescriptor, SOMAXCONN ) == -1 {
      let details = descriptionOfLastError()
      release(socket: socketFileDescriptor)
      return (false, "\(port), ListenFailed, \(details)")
    }
    release(socket: socketFileDescriptor)
    return (true, "\(port) is free for use")
  }
  
  static func release(socket: Int32) {
    Darwin.shutdown(socket, SHUT_RDWR)
    close(socket)
  }
  static func descriptionOfLastError() -> String {
    return String(cString: UnsafePointer(strerror(errno))) 
  }
}

