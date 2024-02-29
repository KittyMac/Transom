import TransomFramework
import ArgumentParser
import Foundation

struct Translate: ParsableCommand {
    
    @Flag(help: "Translate to kotlin")
    var kotlin: Bool = false
    
    @Flag(help: "Translate to typescript")
    var typescript: Bool = false
    
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
            var languages: [Language] = []
            
            if kotlin {
                languages.append(.kotlin)
            }
            if typescript {
                languages.append(.typescript)
            }
            
            for language in languages {
                TransomFramework.shared.translate(language: language,
                                                  file: inFile,
                                                  outputDirectory: outputDirectory)
            }
        }
    }

}

Translate.main()

