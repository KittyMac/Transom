import Jib
import Hitch
import Foundation

public enum Language: String {
    case kotlin = "kotlin"
    case typescript = "typescript"
    
    func ext() -> String {
        switch self {
        case .kotlin: return "kt"
        case .typescript: return "tsx"
        }
    }
    
    func compiler() -> String? {
        switch self {
        case .kotlin: return "kotlinc"
        case .typescript: return nil
        }
    }
}

public class TransomFramework {
    public static let shared = TransomFramework()
    
    public func translate(language: Language,
                          path: String) -> String? {
        guard let swift = try? String(contentsOfFile: path) else { return nil }
        
        if swift.contains("// \(language.rawValue):") == false && swift.contains("//\(language.rawValue):") == false {
            return "\n// no \(language.rawValue) tags found, skipping...\n"
        }
                
        let jib = Jib()
        
        _ = jib.eval("let transom = {};")!
        
        switch language {
        case .kotlin:
            _ = jib.eval(TransomFrameworkPamphlet.TransomKotlinMinJs())!
        case .typescript:
            _ = jib.eval(TransomFrameworkPamphlet.TransomTypescriptMinJs())!
        }
        
                
        let jsTransate = jib[function: "transom.translate"]!
        
        let code = jib.call(string: jsTransate, [path, swift])
        guard code != "undefined" else { return nil }
        return code
    }
    
    public func translate(language: Language,
                          inputsFile: String,
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
        
        var codeFiles: [String] = []
        let codeFilesLock = NSLock()
        
        for input in inputFiles {
            queue.addOperation {
                let codeFileName = URL(fileURLWithPath: input).deletingPathExtension().appendingPathExtension(language.ext()).lastPathComponent
                let codeFilePath = outputDirectory + "/" + codeFileName
                
                //print("\(input): warning: transom processing file")
                
                codeFilesLock.lock()
                codeFiles.append(codeFilePath)
                codeFilesLock.unlock()
                
                try? FileManager.default.removeItem(atPath: codeFilePath)
                if let code = self.translate(language: language, path: input) {
                    try? code.write(toFile: codeFilePath, atomically: false, encoding: .utf8)
                } else {
                    success = false
                }
            }
        }
        
        queue.waitUntilAllOperationsAreFinished()
        
        if success && codeFiles.count > 0 {
            success = compile(language: language,
                              files: codeFiles,
                              outputDirectory: outputDirectory)
        }
        
        let canaryFilePath = outputDirectory + "/canary.swift"
        try? FileManager.default.removeItem(atPath: canaryFilePath)
        if success {
            try! "".write(toFile: canaryFilePath, atomically: false, encoding: .utf8)
        } else {
            try! #"#error("Swift translation failed; please fix build errors to proceed")"#.write(toFile: canaryFilePath, atomically: false, encoding: .utf8)
        }
        
        if success == false {
            exit(1)
        }
    }
    
    public func translate(language: Language,
                          file input: String,
                          outputDirectory: String) {
        if input.hasSuffix("inputFiles.txt") {
            return translate(language: language,
                             inputsFile: input,
                             outputDirectory: outputDirectory)
        }
        
        let codeFileName = URL(fileURLWithPath: input).deletingPathExtension().appendingPathExtension(language.ext()).lastPathComponent
        let codeFilePath = outputDirectory + "/" + codeFileName
        
        try? FileManager.default.removeItem(atPath: codeFilePath)
        if let code = self.translate(language: language, path: input) {
            try? code.write(toFile: codeFilePath, atomically: false, encoding: .utf8)
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
    fileprivate func compile(language: Language,
                             files: [String],
                             outputDirectory: String) -> Bool {
        guard let compilerName = language.compiler() else { return true }
        
        let path = pathFor(executable: compilerName)
        
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
                    if line.contains(".\(language.ext()):") {
                        print(outputDirectory + "/" + line)
                    }
                }
            }
            
            task.waitUntilExit()
            
            return task.terminationStatus == 0
        } catch {
            print("\(path): warning: kotlinc failed with error: \(error)")
            return true
        }
    }
}
