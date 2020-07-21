//
//  StringExtension.swift
//  AnonApp
//
//  Created by Matthew Capriotti on 7/19/20.
//  Copyright © 2020 Matthew Capriotti. All rights reserved.
//

import Foundation


extension String
{
    func encodeUrl() -> String?
    {
        return self.addingPercentEncoding( withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
    }
    func decodeUrl() -> String?
    {
        return self.removingPercentEncoding
    }
}
