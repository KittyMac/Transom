import Jib
import Hitch
import Foundation

public class TransomFramework {
    public static let shared = TransomFramework()
    
    public func translate(path: String) -> String? {
        guard let swift = try? String(contentsOfFile: path) else { return nil }
        
        if swift.contains("// kotlin:") == false && swift.contains("//kotlin:") == false {
            return "\n// no kotlin tags found, skipping...\n"
        }
                
        let jib = Jib()
        
        _ = jib[eval: "let transom = {};"]!
        _ = jib[eval: TransomFrameworkPamphlet.TransomMinJs()]!
                
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
        
        var kotlinFiles: [String] = []
        
        for input in inputFiles {
            queue.addOperation {
                let kotlinFileName = URL(fileURLWithPath: input).deletingPathExtension().appendingPathExtension("kt").lastPathComponent
                let kotlinFilePath = outputDirectory + "/" + kotlinFileName
                
                //print("\(input): warning: transom processing file")
                
                kotlinFiles.append(kotlinFilePath)
                
                try? FileManager.default.removeItem(atPath: kotlinFilePath)
                if let kotlin = self.translate(path: input) {
                    try? kotlin.write(toFile: kotlinFilePath, atomically: false, encoding: .utf8)
                } else {
                    success = false
                }
            }
        }
        
        queue.waitUntilAllOperationsAreFinished()
        
        if success && kotlinFiles.count > 0 {
            success = compile(files: kotlinFiles,
                              outputDirectory: outputDirectory)
        }
        
        let canaryFilePath = outputDirectory + "/canary.swift"
        try? FileManager.default.removeItem(atPath: canaryFilePath)
        if success {
            try! "".write(toFile: canaryFilePath, atomically: false, encoding: .utf8)
        } else {
            try! #"#error("Swift to Kotlin translation failed; please fix build errors to proceed")"#.write(toFile: canaryFilePath, atomically: false, encoding: .utf8)
        }
        
        if success == false {
            exit(1)
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
        
        try? FileManager.default.removeItem(atPath: kotlinFilePath)
        if let kotlin = self.translate(path: input) {
            try? kotlin.write(toFile: kotlinFilePath, atomically: false, encoding: .utf8)
        }
    }
    
    
    fileprivate func pathFor(executable name: String) -> String {
        if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/\(name)") {
            return "/opt/homebrew/bin/\(name)"
        } else if FileManager.default.fileExists(atPath: "/usr/bin/\(name)") {
            return "/usr/bin/\(name)"
        } else if FileManager.default.fileExists(atPath: "/usr/local/bin/\(name)") {
            return "/usr/local/bin/\(name)"
        } else if FileManager.default.fileExists(atPath: "/bin/\(name)") {
            return "/bin/\(name)"
        }
        return "./\(name)"
    }
    
    @discardableResult
    fileprivate func compile(files: [String],
                             outputDirectory: String) -> Bool {
        let path = pathFor(executable: "kotlinc")
        
        do {
            if FileManager.default.fileExists(atPath: path) == false {
                print("\(path): warning: kotlinc could not be found, please install (brew install kotlin)")
                return true
            }
            
            let task = Process()
            task.currentDirectoryURL = URL(fileURLWithPath: outputDirectory)
            task.executableURL = URL(fileURLWithPath: path)
            task.arguments = files
            
            let outputPipe = Pipe()
            task.standardError = outputPipe
            
            try task.run()
            
            // note: kotlinc only includes a relative path to error lines, we need to
            // convert this to absolute paths so xcode can resolve the file
            let taskData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            if let taskString = String(data: taskData, encoding: .utf8) {
                let lines = taskString.components(separatedBy: "\n")
                for line in lines {
                    if line.contains(".kt:") {
                        print(outputDirectory + "/" + line)
                    }
                }
            }
            
            return task.terminationStatus == 0
        } catch {
            print("\(path): warning: kotlinc failed with error: \(error)")
            return true
        }
    }
}
