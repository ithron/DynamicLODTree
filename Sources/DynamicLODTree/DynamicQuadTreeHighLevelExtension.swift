//
//  DynamicQuadTreeHighLevelExtension.swift
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

public extension DynamicLODTree {
  func grow(inDirectionOf point: Position) {
    let dir = point &- origin
    let direction = DiagonalDirection.from(vector: dir)
    
    grow(inDirection: direction)
  }
  
  func grow(toContainPoint point: Position) {
    while !rootNode.contains(point: point) {
      grow(inDirectionOf: point)
    }
    
    assert(rootNode.contains(point: point))
  }
  
  func grow(toContainCircle circle: (origin: Position, radius: Scalar)) -> Bool {
    let points = [
      circle.origin &+ Position(circle.radius, 0),
      circle.origin &- Position(circle.radius, 0),
      circle.origin &+ Position(0, circle.radius),
      circle.origin &- Position(0, circle.radius)
    ]
    
    if points.allSatisfy({ self.rootNode.contains(point: $0) }) {
      return false
    }
    points.forEach { self.grow(toContainPoint: $0) }
    return true
  }
  
  func prune(outsideOf circle: (origin: Position, radius: Scalar)) -> Bool {
    let squaredRadius = circle.radius * circle.radius
    
    var modified = false
    
    // Remove all nodes that are completely outside the circle
    var node = rootNode
    var nextNode: NodeType? = node
    
    while nextNode != nil {
      node = nextNode!
      let maxPoint = node.origin &+ node.size
      let nearestPoint = circle.origin.clamped(lowerBound: node.origin,
                                               upperBound: maxPoint)
      let delta = circle.origin &- nearestPoint
      let squaredLength = Position.dot(delta, delta)
      
      if squaredLength > squaredRadius {
        node.prune()
        modified = true
        if let nextNeighbor = node.nextNeighbor {
          nextNode = nextNeighbor
        } else {
          return modified
        }
      } else {
        nextNode = node.next()
      }
    }
    
    return modified
  }
  
  func fit(to circle: (origin: Position, radius: Scalar)) -> Bool {
    // Ensure the circle is contained in the tree
    let grown = grow(toContainCircle: circle)
    // Prune all nodes outside the circle
    let pruned = prune(outsideOf: circle)
    return grown || pruned
  }
}

extension DynamicLODTree.DiagonalDirection {
  static func from(vector: Position) -> DynamicLODTree.DiagonalDirection {
    switch (vector.x, vector.y) {
    case (..<0, ..<0):
      return .downLeft
    case (..<0, 0...):
      return .upLeft
    case (0..., ..<0):
      return .downRight
    case (0..., 0...):
      return .upRight
    case (_, _):
      fatalError("Unreachable code reached")
    }
  }
}
