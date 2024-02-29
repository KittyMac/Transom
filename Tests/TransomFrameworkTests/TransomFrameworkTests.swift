// kotlin: package com.smallplanet.roverandroid
// typescript: 

import XCTest
import TransomFramework

final class TransomFrameworkTests: XCTestCase {
    
    func testBadCode() {
        let x: Int = 5
        let y: Int = 27
        if x < y {
            print("true")
        }
        print(x<y)
    }
    
    func testExample() throws {
        //measure {
        //    TransomFramework.shared.translate(file: "/Users/rjbowli/Library/Developer/Xcode/DerivedData/smallplanet_RoverCore_SDK-chvrhtltmvffplfrunnmjdkpfizx/SourcePackages/smallplanet_rovercore_sdk/RoverCore/TransomPlugin/inputFiles.txt",
        //                                      outputDirectory: "/Users/rjbowli/Library/Developer/Xcode/DerivedData/smallplanet_RoverCore_SDK-chvrhtltmvffplfrunnmjdkpfizx/SourcePackages/smallplanet_rovercore_sdk/RoverCore/TransomPlugin")
        //}
    }
}

