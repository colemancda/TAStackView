//
//  StackContainerView.swift
//  TAStackView
//
//  Created by Tom Abraham on 8/10/14.
//  Copyright (c) 2014 Tom Abraham. All rights reserved.
//

import UIKit

class StackContainerView : UIView {
  private var _gravityAreaContainingView = Dictionary<UnsafePointer<Void>, StackViewGravityArea>()

  required init(coder aDecoder: NSCoder) {
    fatalError("NSCoder not supported")
  }

  override init() {
    super.init(frame: CGRectZero)

    for gravityAreaView in gravityAreaViewsArray {  addSubview(gravityAreaView) }
    for spacerView in gravityAreaSpacerViewsArray { addSubview(spacerView) }

    _installConstraints()
  }

  func _installConstraints() {
    for gravityAreaView in gravityAreaViewsArray { gravityAreaView.setTranslatesAutoresizingMaskIntoConstraints(false) }
  }

  let gravityAreaViews = (
    top: StackGravityAreaView(),
    leading: StackGravityAreaView(),
    center: StackGravityAreaView(),
    trailing: StackGravityAreaView(),
    bottom: StackGravityAreaView()
  )

  let gravityAreaSpacerViews = (
    spacer1: StackSpacerView(),
    spacer2: StackSpacerView()
  )

  private var gravityAreaViewsArray : [StackGravityAreaView] {
    return [ gravityAreaViews.top, gravityAreaViews.leading, gravityAreaViews.center, gravityAreaViews.trailing, gravityAreaViews.bottom ]
  }

  private var gravityAreaSpacerViewsArray : [StackSpacerView] {
    return [ gravityAreaSpacerViews.spacer1, gravityAreaSpacerViews.spacer2 ]
  }
  
  var spacing : Float = DefaultSpacing {
    didSet {
      gravityAreaViewsArray.map({ $0.spacing = self.spacing })

      setNeedsUpdateConstraints()
    }
  }

  var hasEqualSpacing : Bool = false {
    didSet { setNeedsUpdateConstraints() }
  }

  var alignment : NSLayoutAttribute = DefaultAlignment {
    didSet {
      if (oldValue == alignment) { return }

      gravityAreaViewsArray.map({ $0.alignment = self.alignment })
    }
  }

  var orientation : TAUserInterfaceLayoutOrientation = DefaultOrientation {
    didSet {
      if (oldValue == orientation) { return }

      gravityAreaViewsArray.map({ $0.orientation = self.orientation })
      gravityAreaSpacerViewsArray.map({ $0.orientation = self.orientation })

      setNeedsUpdateConstraints()
    }
  }

  func clippingResistancePriorityForAxis(axis : UILayoutConstraintAxis) -> UILayoutPriority {
    return 999//UILayoutPriorityDefaultHigh
  }

  func huggingPriorityForAxis(axis : UILayoutConstraintAxis) -> UILayoutPriority {
    return 250//UILayoutPriorityDefaultLow
  }
  
  func setVisibilityPriority(visibilityPriority : StackViewVisibilityPriority, forView view : UIView) {
    gravityAreaViewForGravity(gravityAreaContainingView(view)).setVisibilityPriority(visibilityPriority, forView: view)
    
    setNeedsUpdateConstraints()
  }
  
  func visibilityPriorityForView(view : UIView) -> StackViewVisibilityPriority {
    return gravityAreaViewForGravity(gravityAreaContainingView(view)).visibilityPriorityForView(view)
  }
  
  func setCustomSpacing(spacing: Float?, afterView view: UIView) {
    gravityAreaViewForGravity(gravityAreaContainingView(view)).setCustomSpacing(spacing, afterView: view)
    
    setNeedsUpdateConstraints()
  }
  
  func customSpacingAfterView(view : UIView) -> Float? {
    return gravityAreaViewForGravity(gravityAreaContainingView(view)).customSpacingAfterView(view)
  }
  
  func setGravityArea(gravityArea : StackViewGravityArea, containingView view: UIView) {
    _gravityAreaContainingView[unsafeAddressOf(view)] = gravityArea
  }
  
  func gravityAreaContainingView(view : UIView) -> StackViewGravityArea {
    return _gravityAreaContainingView[unsafeAddressOf(view)]!
  }
  
  func addView(var view : UIView, inGravity gravity: StackViewGravityArea) {
    setGravityArea(gravity, containingView: view)
    gravityAreaViewForGravity(gravity).addView(view)
    
    setNeedsUpdateConstraints()
  }

  override func updateConstraints() {
    let axis = orientation.toAxis()

    let head = orientation == .Horizontal ? gravityAreaViews.leading : gravityAreaViews.top
    let center = gravityAreaViews.center
    let tail = orientation == .Horizontal ? gravityAreaViews.trailing : gravityAreaViews.bottom
        
    let spacer1 = gravityAreaSpacerViews.spacer1
    let spacer2 = gravityAreaSpacerViews.spacer2

    let views = [
      "head": head,
      "spacer1": spacer1,
      "center": center,
      "spacer2": spacer2,
      "tail": tail
    ]

    let char = orientation.toCharacter()

    func _mainConstraintsForAxis() -> [NSLayoutConstraint] {
      var vfls : [String] = []
      
      if (head.shouldShow && center.shouldShow && tail.shouldShow) {       // 111
        vfls = [ "\(char):|[head][spacer1][center][spacer2][tail]|" ]
      } else if (head.shouldShow && center.shouldShow && !tail.shouldShow) { // 110
        vfls = [ "\(char):|[head][spacer1][center][spacer2]|" ]
      } else if (head.shouldShow && !center.shouldShow && tail.shouldShow) { // 101
        vfls = [ "\(char):|[head][spacer1][tail]|" ]
      } else if (head.shouldShow && !center.shouldShow && !tail.shouldShow) {  // 100
        vfls = [ "\(char):|[head][spacer1]|" ]
      } else if (!head.shouldShow && center.shouldShow && tail.shouldShow) { // 011
        vfls = [ "\(char):|[spacer1][center][spacer2][tail]|" ]
      } else if (!head.shouldShow && center.shouldShow && !tail.shouldShow) {  // 010
        vfls = [ "\(char):|[spacer1][center][spacer2]|" ]
      } else if (!head.shouldShow && !center.shouldShow && tail.shouldShow) {  // 001
        vfls = [ "\(char):|[spacer1][tail]|" ]
      } else if (head.shouldShow && center.shouldShow && tail.shouldShow) { // 000
        // TODO
      }
      
      return NSLayoutConstraint.constraintsWithVisualFormats(vfls, options: NSLayoutFormatOptions(0), metrics: [:], views: views)
    }
    
    func _updateInterGravityAreaSpacing() {
      let hP = huggingPriorityForAxis(axis)

      spacer1.spacing = head.shouldShow && (center.shouldShow || tail.shouldShow) ? head.spacingAfter : 0
      spacer1.spacingPriority = hP
      
      spacer2.spacing = center.shouldShow && tail.shouldShow ? center.spacingAfter : 0
      spacer2.spacingPriority = hP
    }
    
    func _centerGravityAreaCenteringConstraint() -> NSLayoutConstraint {
      let centeringAttribute : NSLayoutAttribute = orientation == .Horizontal ? .CenterX : .CenterY
      
      let centeringConstraint = NSLayoutConstraint(
        item: center, attribute: centeringAttribute,
        relatedBy: .Equal,
        toItem: self, attribute: centeringAttribute,
        multiplier: 1, constant: 0)
      
      centeringConstraint.priority = 250//UILayoutPriorityDefaultLow

      return centeringConstraint;
    }
    
    func _constraintsForOtherAxis() -> [NSLayoutConstraint] {
      let otherChar = orientation.other().toCharacter()
      let vfls = [ "\(otherChar):|[head]|", "\(otherChar):|[center]|", "\(otherChar):|[tail]|"]
      return NSLayoutConstraint.constraintsWithVisualFormats(vfls,
        options: NSLayoutFormatOptions(0), metrics: [:], views: views)
    }


    removeConstraints(constraints())
    addConstraints(_mainConstraintsForAxis())
    addConstraint(_centerGravityAreaCenteringConstraint())
    addConstraints(_constraintsForOtherAxis())
    
    _updateInterGravityAreaSpacing()

    super.updateConstraints()
  }
  
  private func gravityAreaViewForGravity(gravity : StackViewGravityArea) -> StackGravityAreaView {
    switch (gravity) {
    case .Top:
      return gravityAreaViews.top
    case .Leading:
      return gravityAreaViews.leading
    case .Center:
      return gravityAreaViews.center
    case .Trailing:
      return gravityAreaViews.trailing
    case .Bottom:
      return gravityAreaViews.bottom
    }
  }
}