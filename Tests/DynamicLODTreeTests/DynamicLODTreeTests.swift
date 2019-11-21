//
//  DynamicQuadTreeTests.swift
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

import DynamicLODTree
import XCTest

class DynamicLODTreeTests: XCTestCase {
  typealias Position = SIMD2<Int32>
  typealias Tree = DynamicLODTree<Int, Position>
  
  override func setUp() {
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }
  
  func testIfNewTreeContainsSingleLeaf() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 23)
    
    XCTAssert(tree.depth == 23)
    XCTAssertEqual(tree.origin, Position.zero)
    
    XCTAssertTrue(tree.rootNode.isLeaf)
    
    XCTAssertEqual(tree.nodeCount, 1)
    XCTAssertEqual(tree.leafCount, 1)
  }
  
  func testIfRootNodeIsNotRemovable() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 0)
    tree.rootNode.prune()
    
    XCTAssertFalse(tree.rootNode.isVolatile)
  }
  
  func testIfSubdivideCreatesNewLeafs() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 1)
    tree.rootNode.subdivide()
    
    XCTAssertEqual(tree.depth, 1)
    XCTAssertEqual(tree.nodeCount, 5)
    XCTAssertEqual(tree.leafCount, 4)
  }
  
  func testIfTreeContainsPointAfterGrowUpLeft() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 0)
    tree.grow(inDirection: .upLeft)
    
    XCTAssertTrue(tree.rootNode.contains(point: Position(-1, 0)))
    XCTAssertTrue(tree.rootNode.contains(point: Position(0, 0)))
    XCTAssertTrue(tree.rootNode.contains(point: Position(0, 1)))
    XCTAssertTrue(tree.rootNode.contains(point: Position(-1, 1)))
  }
  
  func testIfTreeContainsPointAfterGrowUpRight() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 0)
    tree.grow(inDirection: .upRight)
    
    XCTAssertTrue(tree.rootNode.contains(point: Position(0, 0)))
    XCTAssertTrue(tree.rootNode.contains(point: Position(1, 0)))
    XCTAssertTrue(tree.rootNode.contains(point: Position(0, 1)))
    XCTAssertTrue(tree.rootNode.contains(point: Position(1, 1)))
  }
  
  func testIfTreeContainsPointAfterGrowDownRight() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 0)
    tree.grow(inDirection: .downRight)
    
    XCTAssertTrue(tree.rootNode.contains(point: Position(0, 0)))
    XCTAssertTrue(tree.rootNode.contains(point: Position(1, 0)))
    XCTAssertTrue(tree.rootNode.contains(point: Position(0, -1)))
    XCTAssertTrue(tree.rootNode.contains(point: Position(1, -1)))
  }
  
  func testIfTreeContainsPointAfterGrowDwonLeft() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 0)
    tree.grow(inDirection: .downLeft)
    
    XCTAssertTrue(tree.rootNode.contains(point: Position(0, 0)))
    XCTAssertTrue(tree.rootNode.contains(point: Position(-1, 0)))
    XCTAssertTrue(tree.rootNode.contains(point: Position(0, -1)))
    XCTAssertTrue(tree.rootNode.contains(point: Position(-1, -1)))
  }
  
  func testIfPruneMarksLeafAsVolatile() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 1)
    tree.rootNode.subdivide()
    let leaf = tree.rootNode.nextLeaf()
    leaf?.prune()
    
    XCTAssertTrue(leaf?.isVolatile ?? false)
  }
  
  func testIfPruneOfAllSubnodesPrunesParent() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 2)
    tree.rootNode.subdivide()
    
    let node = tree.rootNode.children!.first
    node.subdivide()
    node.children!.forEach { $0.prune() }
    
    XCTAssertTrue(node.isVolatile)
  }
  
  func testIfPruneDoesNothingOnRootNode() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 0)
    tree.rootNode.prune()
    
    XCTAssertFalse(tree.rootNode.isVolatile)
  }
  
  func testIfTreeAfterGrowToContainCircleContainsCircle() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 0)
    let circle = (origin: Position(-10, 10), radius: Int32(200))
    
    _ = tree.grow(toContainCircle: circle)
    
    XCTAssertTrue(tree.rootNode.contains(point: circle.origin))
    XCTAssertTrue(tree.rootNode.contains(point:
      circle.origin &- circle.radius &* Position(-1, 0)))
    XCTAssertTrue(tree.rootNode.contains(point:
      circle.origin &- circle.radius &* Position(1, 0)))
    XCTAssertTrue(tree.rootNode.contains(point:
      circle.origin &- circle.radius &* Position(0, -1)))
    XCTAssertTrue(tree.rootNode.contains(point:
      circle.origin &- circle.radius &* Position(0, 1)))
  }
  
  func testIfMultipleCallToGrowToContainCircleIsEquivalentToSingleCall() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 0)
    let circle = (origin: Position(-10, 10), radius: Int32(200))
    
    _ = tree.grow(toContainCircle: circle)
    
    let depth = tree.depth
    let origin = tree.origin
    
    _ = tree.grow(toContainCircle: circle)
    
    XCTAssertEqual(tree.depth, depth)
    XCTAssertEqual(tree.origin, origin)
  }
  
  func testIfNodeNextTraversesAllNodes() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 2)
    tree.rootNode.subdivide()
    tree.rootNode.children!.first.subdivide()
    
    let allNodes = [tree.rootNode] +
      tree.rootNode.children! +
      tree.rootNode.children!.first.children!
    
    var visitedNodes: [Tree.NodeType] = []
    
    var node: Tree.NodeType? = tree.rootNode
    repeat {
      visitedNodes.append(node!)
      node = node!.next()
    } while node != nil
    
    // Use A == B iff A in B and B in A
    
    // test if allNodes are contained in visitedNodes
    for node in allNodes {
      XCTAssertTrue(visitedNodes.contains { node === $0 })
    }
    
    // test if visitedNodes are contained in allNodes
    for node in visitedNodes {
      XCTAssertTrue(allNodes.contains { node === $0 })
    }
  }
  
  func testIfTreeNodeSequenceContainsRootNode() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 0)
    
    XCTAssertTrue(tree.nodes.contains { $0 === tree.rootNode })
  }
  
  func testIfTreeNodeSequenceConsistsOfAllNodes() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 1)
    tree.rootNode.subdivide()
    
    let allNodes = [tree.rootNode] + tree.rootNode.children!
    let treeNodes = tree.nodes
    
    // Use A == B iff A in B and B in A
    
    // test if allNodes are contained in treeNodes
    for node in allNodes {
      XCTAssertTrue(treeNodes.contains { node === $0 })
    }
    
    // test if treeNodes are contained in allNodes
    for node in treeNodes {
      XCTAssertTrue(allNodes.contains { node === $0 })
    }
  }
  
  func testIfSingleChildNodeIsRootNodeAfterShrink() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 1)
    tree.rootNode.subdivide()
    
    tree.rootNode.children!.bottomLeft.prune()
    tree.rootNode.children!.bottomRight.prune()
    tree.rootNode.children!.topLeft.prune()
    
    let node = tree.rootNode.children!.topRight
    
    tree.shrink()
    
    XCTAssertTrue(node === tree.rootNode)
  }
  
  func testIfTreeLeafSequenceContainsOnlyLeafs() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 1)
    tree.rootNode.subdivide()
    
    for node in tree.leafs {
      XCTAssertTrue(node.isLeaf)
    }
  }
  
  func testIfRootNodeIsIsolated() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 1)
    tree.rootNode.subdivide()
    
    XCTAssertNil(tree.rootNode.nextNeighbor)
  }
  
  func testIfSisterNodesAreNeighbors() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 1)
    tree.rootNode.subdivide()
    
    var node = tree.rootNode.children!.first
    
    XCTAssertTrue(node.nextNeighbor === node.next())
    node = node.next()!
    XCTAssertTrue(node.nextNeighbor === node.next())
    node = node.next()!
    XCTAssertTrue(node.nextNeighbor === node.next())
    node = node.next()!
    XCTAssertNil(node.nextNeighbor)
  }
  
  func testIfCanFindNeighborAtHigherDepth() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 2)
    tree.rootNode.subdivide()
    tree.rootNode.children!.first.subdivide()
    
    let leaf = tree.nodes.first(where: { $0.isLeaf })!.next()!.next()!.next()!
    let neighbor = tree.rootNode.children!.bottomRight
    
    XCTAssertTrue(leaf.nextNeighbor === neighbor)
  }
  
  func testIfCanFindNeighborAtEqualDepth() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 2)
    tree.rootNode.subdivide()
    tree.rootNode.children!.first.subdivide()
    tree.rootNode.children!.bottomRight.subdivide()
    
    let leaf = tree.nodes.first(where: { $0.isLeaf })!.next()!.next()!.next()!
    let neighbor = tree.rootNode.children!.bottomRight.children!.first
    
    XCTAssertTrue(leaf.nextNeighbor === neighbor)
  }
  
  func testIfPruneOutsideOfCircleDoesNotPruneSingleNode() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 3)
    
    let circle = (origin: tree.origin &+ tree.rootNode.stride,
                  radius: Int32(1))
    
    let modified = tree.prune(outsideOf: circle)
    
    XCTAssertFalse(tree.rootNode.isVolatile)
    XCTAssertFalse(modified)
  }
  
  func testIfPruneOutsideOfCircleDoesNotPruneNodesInside() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 2)
    tree.nodes.forEach { $0.subdivide() }
    
    let circle = (origin: Position(2, 2), radius: Int32(2))
    
    let modified = tree.prune(outsideOf: circle)
    
    XCTAssertFalse(tree.nodes.contains(where: { $0.isVolatile }))
    XCTAssertFalse(modified)
  }
  
  func testIfPruneOutsideOfCirclePrunesNodesOutside() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 2)
    tree.rootNode.subdivide()
    
    let circle = (origin: Position.zero, radius: Int32(1))
    
    let modified = tree.prune(outsideOf: circle)
    
    XCTAssertFalse(tree.rootNode.children!.bottomLeft.isVolatile)
    XCTAssertTrue(tree.rootNode.children!.bottomRight.isVolatile)
    XCTAssertTrue(tree.rootNode.children!.topLeft.isVolatile)
    XCTAssertTrue(tree.rootNode.children!.topRight.isVolatile)
    XCTAssertTrue(modified)
  }
  
  func testIfFitToCircleDoesContainAllInsideNodesAndNoOutsideNode() {
    let tree = Tree(initialOrigin: Position.zero)
    let circle = (origin: Position(2, 2), radius: Int32(1))
    let modified = tree.fit(to: circle)
    
    XCTAssertTrue(modified)
    XCTAssertFalse(tree.grow(toContainCircle: circle))
    
    XCTAssertTrue(tree.rootNode.children!.allSatisfy { !$0.isVolatile })
    XCTAssertTrue(tree.rootNode.children!.bottomLeft.children!.bottomLeft.isVolatile)
    XCTAssertFalse(tree.rootNode.children!.bottomLeft.children!.bottomRight.isVolatile)
    XCTAssertFalse(tree.rootNode.children!.bottomLeft.children!.topLeft.isVolatile)
    XCTAssertFalse(tree.rootNode.children!.bottomLeft.children!.topRight.isVolatile)
    XCTAssertFalse(tree.rootNode.children!.bottomRight.isVolatile)
    XCTAssertFalse(tree.rootNode.children!.topLeft.isVolatile)
    XCTAssertFalse(tree.rootNode.children!.topRight.isVolatile)
  }
  
  func testIfFitToCircleReturnsModifedWhenOnlyPruned() {
    let tree = Tree(initialOrigin: Position.zero)
    let circle = (origin: Position(2, 2), radius: Int32(1))
    _ = tree.grow(toContainCircle: circle)
    
    XCTAssertTrue(tree.fit(to: circle))
  }
  
  func testIfFitToCircleReturnsModifedWhenOnlyGrown() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 1)
    let circle = (origin: Position(2, 2), radius: Int32(1))
    
    XCTAssertTrue(tree.fit(to: circle))
    XCTAssertFalse(tree.nodes.contains(where: { $0.isVolatile }))
  }
}
