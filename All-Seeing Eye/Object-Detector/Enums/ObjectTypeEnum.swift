//
//  ObjectTypeEnum.swift
//  All-Seeing Eye
//
//  Created by vladikkk on 18/05/2020.
//  Copyright © 2020 TMPS. All rights reserved.
//

import UIKit

enum ObservationTypeEnum: String {
    case Person = "person"
//    case Animal = "Animal"
//    case Big_Object = "Big_Object"
//    case Medium_Object = "Medium_Object"
//    case Small_Object = "Small_Object"
//    case Food = "Food"
    case Other = "other"
    
    init(fromRawValue: String) {
        self = ObservationTypeEnum(rawValue: fromRawValue) ?? .Other
    }
    
    func getColor() -> CGColor {
        switch self {
        case .Person:
            return CGColor(srgbRed: 255/255, green: 0, blue: 0, alpha: 1)        // Red
//        case .Animal:
//            return CGColor(srgbRed: 0, green: 255/255, blue: 0, alpha: 1)      // Green
//        case .Big_Object:
//            return CGColor(srgbRed: 0, green: 0, blue: 255/255, alpha: 1)      // Blue
//        case .Medium_Object:
//            return CGColor(srgbRed: 102/255, green: 0, blue: 204/255, alpha: 1)    // Purple
//        case .Small_Object:
//            return CGColor(srgbRed: 255/255, green: 0, blue: 255/255, alpha: 1)    // Magenta
//        case .Food:
//            return CGColor(srgbRed: 255/255, green: 255/255, blue: 0, alpha: 1)    // Yellow
        case .Other:
            return CGColor(srgbRed: 255/255, green: 128/255, blue: 0, alpha: 1)      // Orange
        }
    }
}
