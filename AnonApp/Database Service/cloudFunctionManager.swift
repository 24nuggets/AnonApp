//
//  cloudSessionManager.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 7/3/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import UIKit
import Firebase

class cloudFunctionManager:NSObject {
    let functions = Functions.functions()
    static let sharedInstance = cloudFunctionManager()
    
}
