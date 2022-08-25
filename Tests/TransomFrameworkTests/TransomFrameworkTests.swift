import XCTest
import TransomFramework

final class TransomFrameworkTests: XCTestCase {
    
    func testBadCode() {
        //let test = Blah()
        if false {
            
        }
    }
    
    func testExample() throws {
        
        TransomFramework.shared.translate(file: "/Users/rjbowli/Library/Developer/Xcode/DerivedData/Transom-hfbrfltfpvkvrscztuixgagzspfn/SourcePackages/transom/TransomFrameworkTests/TransomPlugin/inputFiles.txt",
                                          outputDirectory: "/Users/rjbowli/Library/Developer/Xcode/DerivedData/Transom-hfbrfltfpvkvrscztuixgagzspfn/SourcePackages/transom/TransomFrameworkTests/TransomPlugin")
    }
}
