//
//  GeometricQueriesNodeExtension.swift
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

public extension Node {
  /// Computes the squared distance from the square region of the node to the given point
  ///
  /// The returned squared distance is the squared euclidean distance between `point` and the nearest
  /// point on the border of the bounding rectangle of the node. If `point` lies inside the node's rect, the
  /// squared distance is zero.
  ///
  /// - Parameter point: point to compute the squared distance to
  /// - Returns: Squared euclidean distance between `point` and the closest point inside the node's
  ///     region or zero if `point` lies insde the region.
  func squaredDistance(to point: PositionType) -> Scalar {
    let maxPoint = origin &+ size
    let nearestPoint = point.clamped(lowerBound: origin, upperBound: maxPoint)
    let delta = point &- nearestPoint
    let squaredLength = PositionType.dot(delta, delta)
    
    return squaredLength
  }
  
  /// Tests if the node region intersects with the given disk.
  ///
  /// More formally: the function tests if the intersection of`self`and `disk` is non-empty.
  ///
  /// - Parameter disk: `(origin: PositionType, radius:Scalar)`, disk with origin and radius
  /// - Returns: `true` iff the node's area and the disk intersect.
  func intersects(_ disk: (origin: PositionType, radius: Scalar)) -> Bool {
    let dist = squaredDistance(to: disk.origin)
    
    return dist <= (disk.radius * disk.radius)
  }
  
  /// Tests if the node's area lies completly inside the given disk
  ///
  /// More formally: the function tests if `self` is a  subset of `disk`
  ///
  /// - Parameter disk: `(origin: PositionType, radius:Scalar)`, disk with origin and radius
  /// - Returns: `true` iff the node's area in completely included in `disk`
  func isIncluded(in disk: (origin: PositionType, radius: Scalar)) -> Bool {
    let queryPoints = [
      origin,
      origin &+ PositionType(size, 0),
      origin &+ PositionType(0, size),
      origin &+ size
    ]
    
    let rSq = disk.radius * disk.radius
    
    return queryPoints.allSatisfy { q in
      let delta = disk.origin &- q
      let distSq = PositionType.dot(delta, delta)
      return distSq <= rSq
    }
  }
}
