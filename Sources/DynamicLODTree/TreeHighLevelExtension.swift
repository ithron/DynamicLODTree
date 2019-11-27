//
// TreeHighLevelExtension.swift
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

public extension Tree {
  func grow(inDirectionOf point: Position) {
    let dir = point &- origin
    let direction = DiagonalDirection.from(vector: dir)
    
    grow(inDirection: direction)
  }
  
  func grow(toContain point: Position) {
    while !rootNode.contains(point: point) {
      grow(inDirectionOf: point)
    }
    
    assert(rootNode.contains(point: point))
  }
  
  /// Grows the tree so that it covers the complete region bound by the given disk
  ///
  /// The growing is performed so, that no node in the current tree is modfied. Only the root node will
  /// become a child node. If the disk is already contained in the tree, this operations does nothing and
  /// returns `false`.
  ///
  /// - Parameter disk: `(origin: Porisiont, radius: Scalar)` disk defined by origin
  ///   and radius.
  /// - Returns: `true` iff the tree was altered.
  /// - Postcondition: If the tree conainted `disk` nothing is changed, otherwise
  ///  for any point `p` inside `disk`: `tree.contains(point: p) == true` and the original
  ///  branch is completely unchanged.
  func grow(toContain disk: (origin: Position, radius: Scalar)) -> Bool {
    let points = [
      disk.origin &+ Position(disk.radius, 0),
      disk.origin &- Position(disk.radius, 0),
      disk.origin &+ Position(0, disk.radius),
      disk.origin &- Position(0, disk.radius)
    ]
    
    if points.allSatisfy({ self.rootNode.contains(point: $0) }) {
      return false
    }
    points.forEach { self.grow(toContain: $0) }
    return true
  }
  
  /// Prunes all nodes that do not intersect the given disk
  ///
  /// - Parameter disk:`(origin: Porisiont, radius: Scalar)` disk defined by origin
  ///   and radius
  /// - Returns: `true` iff the tree was altered
  /// - Postcondition: For all nodes `n`: if `n.intersects(disk) == false` then
  ///   `n.isVolatile == true`
  func prune(notIntersecting disk: (origin: Position, radius: Scalar)) -> Bool {
    var modified = false
    
    var node = rootNode.nextNotIntersecting(disk)
    
    while let n = node {
      if !n.isVolatile {
        n.prune()
        modified = true
      }
      node = node?.nextNotIntersecting(disk)
    }
    
    return modified
  }
  
  /// Reclaims all nodes that intersects the given disk
  ///
  /// - Parameter disk: `(origin: Position, radius: Scalar)` disk defined by origin
  ///  and radius.
  /// - Returns: `true` iff any node was reclaimed.
  /// - Postcondition: For any node `n` with `n.intersects(disk) == true` =>
  /// `n.isVolatile == false`
  func reclaim(intersecting disk: (origin: Position, radius: Scalar)) -> Bool {
    var modified = false
    
    guard rootNode.intersects(disk) else {
      // If the root node does not intersect the disk, no nodes does.
      return false
    }
    
    var node: Node? = rootNode.nextIntersecting(disk)
    while let n = node {
      if n.isVolatile {
        n.reclaimNonRecursive()
        modified = true
      }
      node = n.nextIntersecting(disk)
    }
    
    return modified
  }
}

extension Tree.DiagonalDirection {
  static func from(vector: Position) -> Tree.DiagonalDirection {
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
