//
// Tree.swift
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

/// A class representing a dynamic spatial quad tree
public class Tree<Content, Position: IntegerPosition2D> {
  public typealias NodeType = Node<Content, Position>
  public typealias Depth = NodeType.Depth
  public typealias Scalar = Position.Scalar
  
  public enum Direction { case left, right, up, down }
  public enum DiagonalDirection: UInt8 {
    case upRight = 0, upLeft, downRight, downLeft
  }
  
  // MARK: - Members
  
  public static var maxDepth: Depth { Depth(UInt64.bitWidth - 1) }
  
  /// The tree's origin (bottom left corner)
  public var origin: Position { rootNode.origin }
  
  /// The tree's depth
  public var depth: Depth { rootNode.depth }
  
  // MARK: Internal
  
  /// The tree's root node
  public internal(set) var rootNode: NodeType
  
  // MARK: - Initializer
  
  /// Initializes a new quad tree at the given position
  ///
  /// - Parameter initialOrigin: The tree's initial origin (bottom left corner)
  /// - Parameter initialDepth: The depth of the initial root node (defaults to 0)
  public init(initialOrigin: Position, initialDepth: Depth = 0) {
    self.rootNode = NodeType(origin: initialOrigin, depth: initialDepth, parent: nil)
  }
  
  // MARK: - Accessors
  
  /// Returns the leaf cell at the given position
  ///
  /// - Parameter position: Query position
  /// - Returns: the current leaf node at the query position or nil if the position lies outside the tree's region
  public func leaf(at position: Position) -> NodeType? {
    guard let node = rootNode.node(at: position, recursive: true) else {
      return nil
    }
    
    guard node.isLeaf else { return nil }
    
    return node
  }
  
  // MARK: - Modifiers
  
  /// Shrinks the tree to its minimal extension
  ///
  /// If all but one children of the root node are volatile, the root node can be replaced by its only
  /// non-volatile node, shrinking the tree by one depth
  ///
  /// - Postcondition: tree.depth >= oldDepth
  public func shrink() {
    guard let children = rootNode.children else { return }
    
    if children.nonVolatileCount == 1 {
      let newRoot = children.firstNonVolatile!
      newRoot.parent = nil
      rootNode = newRoot
    }
  }
  
  /// Grows the tree in the given diagonal direction, doubling its size
  ///
  /// - Parameter direction: direction in which to grow the tree
  /// - Precondition: amount >= 0 && self.depth < maxDepth
  /// - Postcondition: self.depth > oldDepth && self.size == 2 * oldSize
  public func grow(inDirection direction: DiagonalDirection) {
    precondition(depth < Tree<Content, Position>.maxDepth,
                 "depth must not exceed maxDepth")
    
    let newOrigin = Position.min(rootNode.origin &+
      rootNode.size &* direction.vector,
                                 rootNode.origin)
    let newNode = NodeType(origin: newOrigin,
                           depth: rootNode.depth + 1,
                           parent: nil)
    newNode.subdivide()
    
    newNode.children![direction.newRootPosition] = rootNode
    rootNode.parent = newNode
    rootNode = newNode
  }
}

private extension Tree.DiagonalDirection {
  var newRootPosition: NormalizedNodePosition {
    switch self {
    case .downLeft: return .topRight
    case .downRight: return .topLeft
    case .upLeft: return .bottomRight
    case .upRight: return .bottomLeft
    }
  }
  
  var vector: Position {
    switch self {
    case .downLeft: return Position(-1, -1)
    case .downRight: return Position(1, -1)
    case .upRight: return Position(1, 1)
    case .upLeft: return Position(-1, 1)
    }
  }
}
