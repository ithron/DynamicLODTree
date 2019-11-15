//
//  Node.swift
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

public final class Node<Content, PositionType: IntegerPosition2D> {
  public typealias Scalar = PositionType.Scalar
  
  public typealias Depth = UInt8
  
  // MARK: - Members
  
  /// The node's origin (bottom left corner)
  public internal(set) var origin: PositionType
  
  /// The node's depth. Its size is 2^depth
  public let depth: Depth
  
  /// The content associated with the node, optional
  public var content: Content?
  
  /// Child nodes
  public internal(set) var children: SubNodes<Content, PositionType>?
  
  /// The parent node, if nil this is the root node
  public internal(set) weak var parent: Node?
  
  /// A volatile node might be removed on a tree clean up
  public private(set) var isVolatile: Bool = false
  
  /// Test if this node is a leaf, i.e. has no children
  public var isLeaf: Bool { children == nil }
  
  /// test if this node is the root node of a tree
  public var isRoot: Bool { parent == nil }
  
  /// Returns the number of non-volatile childrens
  public var childCount: Int { children?.nonVolatileCount ?? 0 }
  
  /// The node's stride, i.e. the number of elements between two neighboring sub nodes
  public var stride: Scalar { depth > 0 ? (Scalar(1) << Scalar(depth - 1)) : 0 }
  
  /// The size of the node
  public var size: Scalar { Scalar(1) << Scalar(depth) }
  
  // MARK: - Initializer
  
  /// Initializes a node given its origin depth an optionally parent
  ///
  /// - Parameter origin: the origin (bottom left corner) of the node/cell
  /// - Parameter depth: The node's depth. A node with depth 0 must be a leaf
  /// - Parameter parent: Optional parent node
  internal init(origin: PositionType, depth: Depth, parent: Node?) {
    self.origin = origin
    self.depth = depth
    self.parent = parent
  }
  
  // MARK: - Accessors
  
  /// Checks if the given point lies inside the node's cell
  ///
  /// - Parameter point: Point to query
  /// - Returns: true if point lies inside the node's cell, false otherwise
  public func contains(point: PositionType) -> Bool {
    return (origin.x ..< origin.x + size).contains(point.x) &&
      (origin.y ..< origin.y + size).contains(point.y)
  }
  
  /// Returns the child node at the given position
  ///
  /// The the current node is a leaf it self is returned
  ///
  /// - Parameter position: the query position in absolute coordinates
  /// - Parameter recursive: if false (default) the function returns the direct child node,
  ///    if true the leaf node containing position is returned
  ///
  /// - Returns: The child (or leaf) node at the given position or nil if either the position is outside the current patch or
  ///    the current node does not have children
  func node(at position: PositionType, recursive: Bool = false) -> Node? {
    guard contains(point: position) else { return nil }
    
    guard let children = self.children else { return self }
    
    let child = children[toNormalized(position: position)]
    
    assert(child.contains(point: position))
    
    if recursive {
      return child.node(at: position, recursive: true)
    }
    
    return child
  }
  
  // MARK: Internal
  
  /// Converts the given aboslute position into a normalized node position
  ///
  /// - Parameter position: Query position
  /// - Returns: normalized node position of child node at the given position
  /// - Precondition: self.contains(point: position) == true && self.depth > 0
  internal func toNormalized(position: PositionType) -> NormalizedNodePosition {
    assert(contains(point: position))
    assert(depth > 0)
    
    let normalizedPosition = (position &- origin) / stride
    let index = NormalizedNodePosition.RawValue(normalizedPosition.y * 2 + normalizedPosition.x)
    
    return NormalizedNodePosition(rawValue: index)!
  }
  
  internal func originFor(normalizedPosition: NormalizedNodePosition) -> PositionType {
    return origin &+ stride &* PositionType(normalizedPosition)
  }
  
  // MARK: - Modifiers
  
  /// Subdivides the current leaf node/cell into 4 subnodes
  ///
  /// Does nothing if the node is not a leaf or has depth 0
  /// Since a disposable node must not have leaf, the node is no longer disposable after subdivision, if it wa
  /// before.
  public func subdivide() {
    guard depth > 0 else { return }
    
    isVolatile = false
    
    if children == nil {
      let newDepth = depth - 1
      
      children = SubNodes(bottomLeft: Node(origin: originFor(normalizedPosition: .bottomLeft),
                                           depth: newDepth, parent: self),
                          bottomRight: Node(origin: originFor(normalizedPosition: .bottomRight),
                                            depth: newDepth, parent: self),
                          topLeft: Node(origin: originFor(normalizedPosition: .topLeft),
                                        depth: newDepth, parent: self),
                          topRight: Node(origin: originFor(normalizedPosition: .topRight),
                                         depth: newDepth, parent: self))
    }
  }
  
  /// Merges the current subtree into a single node/cell
  /// - Postcondition: self.isLeaf
  public func merge() {
    children = nil
    
    assert(isLeaf)
  }
  
  /// Marks a volatile node as non-volatile
  ///
  /// Has no effect on non-volatile nodes.
  /// If called on a non-leaf node it reclaims the complete branch. If the parent node is mark as volatile,
  /// it will be reclaimed, too.
  /// - Postcondition:self.isVolatile == false
  public func reclaim() {
    guard isVolatile else { return }
    isVolatile = false
    
    // reclaim children
    children?.forEach { $0.reclaim() }
    // reclaim parent
    parent?.reclaim()
  }
  
  /// Removes the node and its sub nodes from the tree
  ///
  /// The node is not directly removed from the tree, but marked as volatile instead.
  /// The root node cannot be discarded, but if disscard is called on the root node,
  /// the complete subtree is pruned.
  /// If all sub nodes of a node are discarded, the parent node will get discarded as well,
  /// making the complete subtree volatile.
  ///
  /// - Postcondition: node.isVolatile == true && node.isLeaf == true
  /// - Note: `prune` never removes a node. All it does it marking nodes as volatile.
  ///    To actually remove a node from the tree call `cleanUp`.
  public func prune() {
    guard !isVolatile else { return }
    
    isVolatile = !isRoot
    
    // Prune children
    children?.forEach { $0.prune() }
    
    // If all neighboring nodes are also volatile, prune the parent node
    if let parent = self.parent {
      if parent.children!.allSatisfy({ $0.isVolatile }) {
        parent.prune()
      }
    }
  }
  
  /// Removes all volatile sub branches.
  ///
  /// - Attention: Might invalidate node iterators
  public func cleanUp() {
    guard isVolatile else { return }
    
    // Test if parent is also marked as volatile. If so, delegate the clean up
    // to him
    if let parent = self.parent {
      if parent.isVolatile {
        parent.cleanUp()
        return
      }
    }
    
    // remove all sub-nodes
    children = nil
  }
  
  // MARK: Internal
  
  /// Replaces the node at the given position with the given new node
  ///
  /// newNode will keep its depth. Therefore the tree is subdivided needed
  ///
  /// - Parameter position: position to insert the node at
  /// - Parameter newNode: the node to insert/replace
  /// - Precondition: self.contains(point: position) == true && self.depth > newNode.depth
  internal func replaceNode(at position: PositionType, with newNode: Node) {
    assert(contains(point: position))
    assert(depth > newNode.depth)
    
    if isLeaf { subdivide() }
    
    let normalizedPos = toNormalized(position: position)
    
    let child = children![normalizedPos]
    
    if child.depth == newNode.depth {
      children![normalizedPos] = newNode
      newNode.parent = self
    } else {
      child.replaceNode(at: position, with: newNode)
    }
  }
}
