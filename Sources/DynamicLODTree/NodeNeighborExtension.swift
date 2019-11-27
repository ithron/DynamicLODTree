//
//  File.swift
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

public extension Tree.Node {
  /// The neight neighbor node, i.e. the next node with the same or a higher depth or nil
  /// if no such node exists
  var nextNeighbor: Tree.Node? {
    guard !isRoot else { return nil }
    
    var parent = self
    var pos: NormalizedNodePosition = NormalizedNodePosition.bottomLeft
    
    // if last child of parent, walk up the tree until another child is available
    while parent.parent != nil {
      parent = parent.parent!
      pos = parent.toNormalized(position: origin)
      if !pos.isLast {
        break
      }
    }
    
    if pos.isLast { return nil }
    
    var node = parent.children![pos.next]
    
    // walk down the tree if either the depth matches our depth or a leaf is
    // reached
    while node.depth > depth {
      guard let children = node.children else { return node }
      node = children.first
    }
    
    return node
  }
}
