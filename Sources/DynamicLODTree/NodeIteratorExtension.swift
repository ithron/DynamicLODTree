//
//  NodeSequenceExtension.swift
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

extension Node {
  public func next() -> Node? {
    // If the current node is a leaf one needs to go up the tree to find the
    // next node
    if isLeaf {
      var nextParent = parent
      
      repeat {
        // if parent is nil, the current node is the root. It's either a leaf or
        // all children have been traversed. In both cases the tree has been
        // completly traversed, so return nil here.
        guard let parent = nextParent else { return nil }
        
        // Get the position of the current node relative to the parent's origin
        var pos = parent.toNormalized(position: origin)
        
        // If there is still a neighboring node left, return it
        if !pos.isLast {
          // Get the next non empty node
          pos = pos.next
          
          return parent.children?[pos]
        }
        
        // No direct neighbor could be found. Go up one level and
        // repeat.
        nextParent = parent.parent
        
      } while true // Loop is exited by return statement
    } // if node.isLeaf
    
    return children!.first
  }
  
  public func nextLeaf() -> Node? {
    var node = next()
    while !(node?.isLeaf ?? true) { node = node?.next() }
    return node
  }
  
  /// Returns the next branch in the tree or nil if the current branch is the last one
  public func nextBranch() -> Node? {
    guard !isRoot else { return nil }
    
    var parent = self
    var pos: NormalizedNodePosition = .bottomLeft
    
    // if last child of parent, walk up the tree until another child is available
    while parent.parent != nil {
      parent = parent.parent!
      pos = parent.toNormalized(position: origin)
      if !pos.isLast {
        break
      }
    }
    
    if pos.isLast { return nil }
    
    let node = parent.children![pos.next]
    
    return node
  }
  
  public func nextNotIntersecting(_ disk: (origin: PositionType, radius: Scalar)) -> Node? {
    var node = next()
    while let n = node {
      if !n.intersects(disk) {
        // Found non intersecting node
        return n
      } else if n.isIncluded(in: disk) {
        // node is completly included in disk, can skip to next neighbor
        node = n.nextBranch()
      } else {
        // the node and the disk intersects but node is no subset of disk,
        // therefore, there might be a child that does not intersect with disk
        node = n.next()
      }
    }
    
    // If no node was found until here, there is no node left
    return nil
  }
  
  /// Returns the next node that intersects the given disk or nil if there are no more intersecrting nodes
  ///
  /// - Parameter disk: `(origin: PositionType, radius: Scalar)` disk to check for
  ///  intersection with
  /// - Postcondition: `let n = nextIntersecting(disk)` then
  /// `n.intersects(disk) == true`
  public func nextIntersecting(_ disk: (origin: PositionType, radius: Scalar)) -> Node? {
    var node = next()
    while let n = node {
      if n.intersects(disk) {
        return n
      } else {
        // if n does not intersect disk, none of the children of n intersects
        node = n.nextBranch()
      }
    }
    
    // If no node was found until here, there is no node left
    return nil
  }
}

public struct NodeIterator<Content, Position: IntegerPosition2D>: IteratorProtocol {
  public typealias Element = Node<Content, Position>
  
  var node: Element?
  
  public func next() -> Node<Content, Position>? {
    return node?.next()
  }
}

public struct LeafIterator<Content, Position: IntegerPosition2D>: IteratorProtocol {
  public typealias Element = Node<Content, Position>
  
  var node: Element?
  
  public func next() -> Node<Content, Position>? {
    return node?.nextLeaf()
  }
}
