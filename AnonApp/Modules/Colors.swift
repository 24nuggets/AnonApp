//
//  Colors.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 7/24/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import Foundation
import UIKit


public var darktint: UIColor = {
    if #available(iOS 13, *) {
        return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
            if UITraitCollection.userInterfaceStyle == .dark {
                /// Return the color for Dark Mode
                return UIColor(hexString: "202020")
            } else {
                /// Return the color for Light Mode
                return .systemBackground
            }
        }
    } else {
        /// Return a fallback color for iOS 12 and lower.
        return .white
    }
}()


