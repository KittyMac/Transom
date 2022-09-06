// kotlin: package com.smallplanet.roverandroid

import XCTest
import TransomFramework

final class TransomFrameworkTests: XCTestCase {
    
    func testBadCode() {
        let x = 5
        let y = 27
        if x < y {
            print("true")
        }
        print(x<y)
    }
    
    func testExample() throws {
        //TransomFramework.shared.translate(file: "/Users/rjbowli/Library/Developer/Xcode/DerivedData/Transom-hfbrfltfpvkvrscztuixgagzspfn/SourcePackages/transom/TransomFrameworkTests/TransomPlugin/inputFiles.txt",
        //                                  outputDirectory: "/Users/rjbowli/Library/Developer/Xcode/DerivedData/Transom-hfbrfltfpvkvrscztuixgagzspfn/SourcePackages/transom/TransomFrameworkTests/TransomPlugin")
    }
}
