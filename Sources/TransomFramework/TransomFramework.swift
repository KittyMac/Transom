import Jib
import Hitch
import Pamphlet
import Foundation

public class TransomFramework {
    public static let shared = TransomFramework()
    
    public func translate(path: String) -> String? {
        guard let swift = try? String(contentsOfFile: path) else { return nil }
        
        let jib = Jib()
        
        _ = jib[eval: "let transom = {};"]!
        _ = jib[eval: Pamphlet.TransomMinJs()]!
                
        let jsTransate = jib[function: "transom.translate"]!
                        
        let kotlin = jib.call(jsTransate, [path, swift])?.toString()
        guard kotlin != "undefined" else { return nil }
        return kotlin
    }
    
    public func translate(inputsFile: String,
                          outputDirectory: String) {
        guard inputsFile.hasSuffix("inputFiles.txt") else {
            fatalError("inputs file is not inputFiles.txt")
        }
        
        guard let inputsFileString = try? String(contentsOfFile: inputsFile) else {
            fatalError("unable to open inputs file \(inputsFile)")
        }
        
        let inputFiles = inputsFileString.split(separator: "\n").map { String($0) }
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = ProcessInfo.processInfo.activeProcessorCount
        
        
        var success = true
        
        for input in inputFiles {
            queue.addOperation {
                let kotlinFileName = URL(fileURLWithPath: input).deletingPathExtension().appendingPathExtension("kt").lastPathComponent
                let kotlinFilePath = outputDirectory + "/" + kotlinFileName
                if let kotlin = self.translate(path: input) {
                    try? kotlin.write(toFile: kotlinFilePath, atomically: false, encoding: .utf8)
                } else {
                    success = false
                    try? FileManager.default.removeItem(atPath: kotlinFilePath)
                }
            }
        }
        
        
        
        queue.waitUntilAllOperationsAreFinished()
        
        let canaryFilePath = outputDirectory + "/canary.swift"
        if success {
            try! "".write(toFile: canaryFilePath, atomically: false, encoding: .utf8)
        } else {
            try! #"#error("Swift to Kotlin translation failed; please fix build errors to proceed")"#.write(toFile: canaryFilePath, atomically: false, encoding: .utf8)
        }
        
    }
    
    public func translate(file input: String,
                          outputDirectory: String) {
        if input.hasSuffix("inputFiles.txt") {
            return translate(inputsFile: input,
                             outputDirectory: outputDirectory)
        }
        
        let kotlinFileName = URL(fileURLWithPath: input).deletingPathExtension().appendingPathExtension("kt").lastPathComponent
        let kotlinFilePath = outputDirectory + "/" + kotlinFileName
        if let kotlin = self.translate(path: input) {
            try? kotlin.write(toFile: kotlinFilePath, atomically: false, encoding: .utf8)
        } else {
            try? FileManager.default.removeItem(atPath: kotlinFilePath)
        }
    }
}
