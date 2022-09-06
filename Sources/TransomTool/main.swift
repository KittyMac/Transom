import TransomFramework
import ArgumentParser

struct Translate: ParsableCommand {
    
    @Argument(help: "Path to Swift file")
    var inFile: String
    
    @Argument(help: "Path to output directory")
    var outputDirectory: String
    
    mutating func run() {
        if inFile != "skip" {
            TransomFramework.shared.translate(file: inFile,
                                              outputDirectory: outputDirectory)
        }
    }

}

Translate.main()

