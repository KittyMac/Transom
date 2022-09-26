import TransomFramework
import ArgumentParser
import Foundation

struct Translate: ParsableCommand {
    
    @Argument(help: "Path to Swift file")
    var inFile: String
    
    @Argument(help: "Path to output directory")
    var outputDirectory: String
    
    mutating func run() {
        if let buildAction = ProcessInfo.processInfo.environment["ACTION"],
           buildAction == "indexbuild" {
            return
        }
        
        if inFile != "skip" {
            TransomFramework.shared.translate(file: inFile,
                                              outputDirectory: outputDirectory)
        }
    }

}

Translate.main()

