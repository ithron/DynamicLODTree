//
//  IntegerPosition2D.swift
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

/// An integer 2D position type
public protocol IntegerPosition2D : AdditiveOverflowArithmetic {
  
  /// The underlying scalar type
  associatedtype Scalar : SignedInteger
  
  /// Access x component
  var x : Scalar {get set}
  /// Access y component
  var y : Scalar {get set}
  
  /// initializable from x and y components without label
  init(_ x : Scalar, _ y : Scalar)
  
  /// Vector scalar multiplication
  static func &*(_ pos : Self, _ scalar : Scalar) -> Self
  /// Scalar vector multiplication
  static func &*(_ scalar : Scalar, _ pos : Self) -> Self
  
  /// Vector by scalar division
  static func /(_ pos : Self, _ scalar : Scalar) -> Self
  
  /// Broadcasting addition
  static func &+(_ pos : Self, _ scalar : Scalar) -> Self
  static func &+(_ scalar : Scalar, pos : Self) -> Self
  
  /// Broadcasting subtraction
  static func &-(_ pos : Self, _ scalar : Scalar) -> Self
  
}

/// A type that is initializable given an x and a y component using labels
public protocol XYInitializable {
  associatedtype Scalar
  
  init(x : Scalar, y : Scalar)
}

/// Adds compatibility for types that use x and y labels in initializer
public extension IntegerPosition2D where Self : XYInitializable {
}

public extension IntegerPosition2D {
  
  static func min(_ lhs: Self, _ rhs: Self) -> Self {
    return Self.init(Swift.min(lhs.x, rhs.x), Swift.min(lhs.y, rhs.y))
  }
  
  
  static func max(_ lhs: Self, _ rhs: Self) -> Self {
    return Self.init(Swift.max(lhs.x, rhs.x), Swift.max(lhs.y, rhs.y))
  }
  
}
