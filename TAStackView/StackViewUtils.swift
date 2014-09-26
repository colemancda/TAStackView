//
//  StackViewUtils.swift
//  TAStackView
//
//  Created by Tom Abraham on 8/10/14.
//  Copyright (c) 2014 Tom Abraham. All rights reserved.
//

import UIKit

typealias StackViewVisibilityPriority = Float

let DefaultSpacing : Float = 8.0
let DefaultAlignment : NSLayoutAttribute = .CenterY
let DefaultOrientation : TAUserInterfaceLayoutOrientation = .Horizontal

extension NSLayoutConstraint {
  class func constraintsWithVisualFormats(
    vfls : [String],
    options : NSLayoutFormatOptions,
    metrics : Dictionary<String, Float>,
    views : Dictionary<String, UIView>
  ) -> [NSLayoutConstraint] {
    let views = views._bridgeToObjectiveC()
    let metrics = metrics._bridgeToObjectiveC()

    var cs : [NSLayoutConstraint] = []
    for vfl in vfls {
      cs += constraintsWithVisualFormat(vfl, options: options, metrics: metrics, views: views) as [NSLayoutConstraint]
    }
    return cs
  }
}

enum TAUserInterfaceLayoutOrientation {
  case Horizontal
  case Vertical

  func toCharacter() -> Character {
    return self == .Horizontal ? "H" : "V"
  }

  func other() -> TAUserInterfaceLayoutOrientation {
    return self == .Horizontal ? .Vertical : .Horizontal;
  }

  func toAxis() -> UILayoutConstraintAxis {
    return self == .Horizontal ? .Horizontal : .Vertical;
  }
}

enum StackViewGravityArea: Int {
  case Top
  case Leading
  case Center
  case Bottom
  case Trailing
}

let TAStackViewSpacingUseDefault = FLT_MAX