//
//  SubNodes.swift
//
// Copyright (c) 2019, Stefan Reinhold
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

public struct SubNodes<Content, Position: IntegerPosition2D> {
  public typealias NodeType = Node<Content, Position>
  
  public var bottomLeft: NodeType
  public var bottomRight: NodeType
  public var topLeft: NodeType
  public var topRight: NodeType
}

public extension SubNodes {
  subscript(position: NormalizedNodePosition) -> NodeType {
    get {
      switch position {
      case .bottomLeft: return bottomLeft
      case .bottomRight: return bottomRight
      case .topLeft: return topLeft
      case .topRight: return topRight
      }
    }
    set {
      switch position {
      case .bottomLeft: bottomLeft = newValue
      case .bottomRight: bottomRight = newValue
      case .topLeft: topLeft = newValue
      case .topRight: topRight = newValue
      }
    }
  }
}

public extension SubNodes {
  var first: NodeType { bottomLeft }
  
  // Number of non-volatile nodes
  var nonVolatileCount: Int {
    reduce(0) { $1.isVolatile ? $0 : $0 + 1 }
  }
  
  // First non-volatile node
  var firstNonVolatile: NodeType? { first { !$0.isVolatile } }
}

public extension SubNodes {
  mutating func swap(_ lhs: NormalizedNodePosition, _ rhs: NormalizedNodePosition) {
    let tmp = self[lhs]
    self[lhs] = self[rhs]
    self[rhs] = tmp
  }
  
  mutating func swapLeftRight() {
    swap(.bottomLeft, .bottomRight)
    swap(.topLeft, .topRight)
  }
  
  mutating func swapBottomTop() {
    swap(.bottomLeft, .topLeft)
    swap(.bottomRight, .topRight)
  }
}

extension SubNodes: Sequence {
  public typealias Iterator = Array<NodeType>.Iterator
  
  public func makeIterator() -> Iterator {
    return [bottomLeft, bottomRight, topLeft, topRight].makeIterator()
  }
}
