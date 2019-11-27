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
  typealias Tree = DynamicLODTree.Tree<Int, Position>
  
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
  
  func testIfTreeAfterGrowToContainDiskContainsDisk() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 0)
    let disk = (origin: Position(-10, 10), radius: Int32(200))
    
    _ = tree.grow(toContain: disk)
    
    XCTAssertTrue(tree.rootNode.contains(point: disk.origin))
    XCTAssertTrue(tree.rootNode.contains(point:
      disk.origin &- disk.radius &* Position(-1, 0)))
    XCTAssertTrue(tree.rootNode.contains(point:
      disk.origin &- disk.radius &* Position(1, 0)))
    XCTAssertTrue(tree.rootNode.contains(point:
      disk.origin &- disk.radius &* Position(0, -1)))
    XCTAssertTrue(tree.rootNode.contains(point:
      disk.origin &- disk.radius &* Position(0, 1)))
  }
  
  func testIfMultipleCallToGrowToContainDiskIsEquivalentToSingleCall() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 0)
    let disk = (origin: Position(-10, 10), radius: Int32(200))
    
    _ = tree.grow(toContain: disk)
    
    let depth = tree.depth
    let origin = tree.origin
    
    _ = tree.grow(toContain: disk)
    
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
    
    var visitedNodes: [Tree.Node] = []
    
    var node: Tree.Node? = tree.rootNode
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
  
  func testIfPruneNotIntersectingDiskDoesNotPruneSingleNode() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 3)
    
    let disk = (origin: tree.origin &+ tree.rootNode.stride,
                radius: Int32(1))
    
    let modified = tree.prune(notIntersecting: disk)
    
    XCTAssertFalse(tree.rootNode.isVolatile)
    XCTAssertFalse(modified)
  }
  
  func testIfPruneNotIntersectingDiskDoesNotPruneNodesInside() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 2)
    tree.nodes.forEach { $0.subdivide() }
    
    let disk = (origin: Position(2, 2), radius: Int32(2))
    
    let modified = tree.prune(notIntersecting: disk)
    
    XCTAssertFalse(tree.nodes.contains(where: { $0.isVolatile }))
    XCTAssertFalse(modified)
  }
  
  func testIfPruneNotIntersectingDiskPrunesIntersectingNodes() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 2)
    tree.rootNode.subdivide()
    
    let disk = (origin: Position.zero, radius: Int32(1))
    
    let modified = tree.prune(notIntersecting: disk)
    
    XCTAssertFalse(tree.rootNode.children!.bottomLeft.isVolatile)
    XCTAssertTrue(tree.rootNode.children!.bottomRight.isVolatile)
    XCTAssertTrue(tree.rootNode.children!.topLeft.isVolatile)
    XCTAssertTrue(tree.rootNode.children!.topRight.isVolatile)
    XCTAssertTrue(modified)
  }
  
  func testIfNodeIntersectsIntersectingDisk() {
    let tree = Tree(initialOrigin: Position.zero)
    let disk = (origin: Position.zero, radius: Int32(1))
    
    XCTAssertTrue(tree.rootNode.intersects(disk))
  }
  
  func testIfNodeDoesNotIntersectDisjointDisk() {
    let tree = Tree(initialOrigin: Position.zero)
    let disk = (origin: Position(-3, 4), radius: Int32(1))
    
    XCTAssertFalse(tree.rootNode.intersects(disk))
  }
  
  func testIfNodeIsNotIncludedInPartiallyOverlappingDisk() {
    let tree = Tree(initialOrigin: Position.zero)
    let disk = (origin: Position.zero, radius: Int32(1))
    
    XCTAssertFalse(tree.rootNode.isIncluded(in: disk))
  }
  
  func testIfNodeIsIncludedInItsBoundingDisk() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 1)
    let disk = (origin: Position(1, 1), radius: Int32(2))
    
    XCTAssertTrue(tree.rootNode.isIncluded(in: disk))
  }
  
  func testIfNextNotIntersectingNodeDoesNotIntersect() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 2)
    tree.rootNode.subdivide()
    tree.rootNode.children!.forEach { $0.subdivide() }
    
    let disk = (origin: Position.zero, radius: Int32(1))
    
    var node: Tree.Node? = tree.rootNode.nextNotIntersecting(disk)
    while let n = node {
      XCTAssertFalse(n.intersects(disk))
      node = n.nextNotIntersecting(disk)
    }
  }
  
  func testIfNextNotIntersectingVisitsAllNotIntersectingNodes() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 2)
    tree.rootNode.subdivide()
    tree.rootNode.children!.forEach { $0.subdivide() }
    
    let disk = (origin: Position.zero, radius: Int32(2))
    
    let refNodes = [tree.rootNode.children!.topRight] +
      [tree.rootNode.children!.bottomRight.children!.topLeft,
       tree.rootNode.children!.bottomRight.children!.topRight,
       tree.rootNode.children!.bottomRight.children!.bottomRight] +
      [tree.rootNode.children!.topLeft.children!.topLeft,
       tree.rootNode.children!.topLeft.children!.topRight,
       tree.rootNode.children!.topLeft.children!.bottomRight] +
      tree.rootNode.children!.topRight.children!
    
    var nodesVisited: [Tree.Node] = []
    
    var node: Tree.Node? = tree.rootNode.nextNotIntersecting(disk)
    while let n = node {
      nodesVisited.append(n)
      node = n.nextNotIntersecting(disk)
    }
    
    // check if all visited nodes are included in refNodes
    XCTAssertTrue(nodesVisited.allSatisfy { ni in
      refNodes.contains {
        nj in
        ni === nj
      }
    })
    
    // check if all refNodes are included in visitedNodes
    XCTAssertTrue(refNodes.allSatisfy { ni in
      nodesVisited.contains {
        nj in
        ni === nj
      }
    })
  }
  
  func testIfNextIntersectingNodesIntersectDisk() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 2)
    tree.rootNode.subdivide()
    tree.rootNode.children!.forEach { $0.subdivide() }
    
    let disk = (origin: Position.zero, radius: Int32(1))
    
    var node: Tree.Node? = tree.rootNode.nextIntersecting(disk)
    while let n = node {
      XCTAssertTrue(n.intersects(disk))
      node = n.nextIntersecting(disk)
    }
  }
  
  func testIfNextIntersectingVisitsAllIntersectingNodes() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 2)
    tree.rootNode.subdivide()
    tree.rootNode.children!.forEach { $0.subdivide() }
    
    let disk = (origin: Position.zero, radius: Int32(2))
    
    let refNodes = tree.rootNode.children!.bottomLeft.children! +
      [tree.rootNode.children!.bottomRight.children!.bottomLeft,
       tree.rootNode.children!.topLeft.children!.bottomLeft,
       tree.rootNode.children!.bottomLeft,
       tree.rootNode.children!.bottomRight,
       tree.rootNode.children!.topLeft]
    
    var nodesVisited: [Tree.Node] = []
    
    var node: Tree.Node? = tree.rootNode.nextIntersecting(disk)
    while let n = node {
      nodesVisited.append(n)
      node = n.nextIntersecting(disk)
    }
    
    // check if all visited nodes are included in refNodes
    XCTAssertTrue(nodesVisited.allSatisfy { ni in
      refNodes.contains {
        nj in
        ni === nj
      }
    })
    
    // check if all refNodes are included in visitedNodes
    XCTAssertTrue(refNodes.allSatisfy { ni in
      nodesVisited.contains {
        nj in
        ni === nj
      }
    })
  }
  
  func testIfReclaimIntersectingDiskReclaimsAllIntersectingNodes() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 2)
    tree.rootNode.subdivide()
    tree.rootNode.children!.forEach { $0.subdivide() }
    
    tree.nodes.forEach { $0.prune() }
    
    let disk = (origin: Position.zero, radius: Int32(2))
    
    let modified = tree.reclaim(intersecting: disk)
    
    XCTAssertTrue(modified)
    
    var node = tree.rootNode.nextIntersecting(disk)
    while let n = node {
      XCTAssertFalse(n.isVolatile)
      node = n.nextIntersecting(disk)
    }
  }
  
  func testIfReclaimIntersectingDiskDoesNotReclaimsNonIntersectingNode() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 2)
    tree.rootNode.subdivide()
    tree.rootNode.children!.forEach { $0.subdivide() }
    
    tree.nodes.forEach { $0.prune() }
    
    let disk = (origin: Position.zero, radius: Int32(2))
    
    let modified = tree.reclaim(intersecting: disk)
    
    XCTAssertTrue(modified)
    
    var node = tree.rootNode.nextNotIntersecting(disk)
    while let n = node {
      XCTAssertTrue(n.isVolatile)
      node = n.nextNotIntersecting(disk)
    }
  }
  
  func testIfNextNonVolatileIsAlwaysNonVolatile() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 2)
    tree.rootNode.subdivide()
    tree.rootNode.children!.forEach { $0.subdivide() }
    let disk = (origin: Position.zero, radius: Int32(2))
    _ = tree.prune(notIntersecting: disk)
    
    var node = tree.rootNode.nextNonVolatile()
    
    while let n = node {
      XCTAssertFalse(node!.isVolatile)
      node = n.nextNonVolatile()
    }
  }
  
  func testIfNextNonVolatileVisitsAllNonVolatileNodes() {
    let tree = Tree(initialOrigin: Position.zero, initialDepth: 2)
    tree.rootNode.subdivide()
    tree.rootNode.children!.forEach { $0.subdivide() }
    let disk = (origin: Position.zero, radius: Int32(2))
    _ = tree.prune(notIntersecting: disk)
    
    let nonVolatileNodes: [Tree.Node] = tree.nodes.lazy.filter { !$0.isVolatile }
    var visitedNodes: [Tree.Node] = [tree.rootNode]
    
    var node = tree.rootNode.nextNonVolatile()
    
    while let n = node {
      XCTAssertTrue(nonVolatileNodes.contains(where: { $0 === n }))
      visitedNodes.append(n)
      node = n.nextNonVolatile()
    }
    
    XCTAssertTrue(nonVolatileNodes.allSatisfy({ i in
      visitedNodes.contains(where: { j in i === j })
    }))
  }
  
  func testIfNextNonVolatileReturnsNilIfTreeIsEmpty() {
    let tree = Tree(initialOrigin: Position.zero)
    
    XCTAssertNil(tree.rootNode.nextNonVolatile())
  }
}
