//
// TreeSequenceExtension.swift
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

public struct TreeNodeIterator<Content, Position: IntegerPosition2D>: IteratorProtocol {
  public typealias Element = Tree<Content, Position>.NodeType
  
  weak var node: Element?
  var isFirst = true
  
  init(node: Element?) {
    self.node = node
  }
  
  public mutating func next() -> Element? {
    if isFirst {
      isFirst = false
    } else {
      guard let node = self.node else { return nil }
      self.node = node.next()
    }
    
    return node
  }
}

public struct TreeNodeSequence<Content, Position: IntegerPosition2D>: Sequence {
  public typealias Iterator = TreeNodeIterator<Content, Position>
  public typealias TreeType = Tree<Content, Position>
  
  var tree: TreeType
  
  init(tree: TreeType) {
    self.tree = tree
  }
  
  public func makeIterator() -> Iterator {
    return Iterator(node: tree.rootNode)
  }
}

public extension Tree {
  /// A sequence over the nodes of the tree
  var nodes: TreeNodeSequence<Content, Position> {
    TreeNodeSequence<Content, Position>(tree: self)
  }
  
  /// A sequence over the leafs of the tree
  var leafs: LazyFilterSequence<TreeNodeSequence<Content, Position>> {
    TreeNodeSequence<Content, Position>(tree: self).lazy.filter {
      $0.isLeaf
    }
  }
  
  /// The number of nodes in the tree
  /// - Complexity: O(n) where n is the number of nodes in the tree
  /// - Attention: Non-constant complexity! Use with care
  /// - See also: nodes.count
  var nodeCount: Int { rootNode.nodeCount }
  
  /// The number of leafs in the tree
  /// - Complexity: O(n) where n is the number of nodes in the tree
  /// - Attention: Non-constant complexity! Use with care
  /// - See also: leafs.count
  var leafCount: Int { rootNode.LeafCount }
}
