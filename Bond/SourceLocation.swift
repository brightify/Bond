//
//  File.swift
//  Bond
//
//  Created by Tadeas Kriz on 26/12/15.
//  Copyright © 2015 Bond. All rights reserved.
//

public struct SourceLocation: CustomDebugStringConvertible {
  let file: String
  let line: UInt
  
  public var debugDescription: String {
    return "\(file):\(line)"
  }
}