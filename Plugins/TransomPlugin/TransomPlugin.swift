import Foundation
import PackagePlugin

@main struct TransomPlugin: BuildToolPlugin {
    
    private func shouldProcess(inputs: [String],
                               outputs: [String]) -> Bool {
        var maxInputDate = Date.distantPast
        var minOutputDate = Date.distantFuture
        
        for input in inputs {
            if let attr = try? FileManager.default.attributesOfItem(atPath: input),
               let date = attr[FileAttributeKey.modificationDate] as? Date {
                if date > maxInputDate {
                    print("input: \(input) is \(date)")
                    maxInputDate = date
                }
            }
        }
        
        for output in outputs {
            if let attr = try? FileManager.default.attributesOfItem(atPath: output),
               let date = attr[FileAttributeKey.modificationDate] as? Date {
                if date < minOutputDate {
                    print("output: \(output) is \(date)")
                    minOutputDate = date
                }
            } else {
                return true
            }
        }
        
        if maxInputDate == Date.distantPast || minOutputDate == Date.distantFuture {
            return true
        }
                
        return minOutputDate < maxInputDate
    }
    
    func gatherSwiftInputFiles(targets: [Target],
                               inputFiles: inout [PackagePlugin.Path]) {
        
        for target in targets {
            let url = URL(fileURLWithPath: target.directory.string)
            if let enumerator = FileManager.default.enumerator(at: url,
                                                               includingPropertiesForKeys: [.isRegularFileKey],
                                                               options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
                for case let fileURL as URL in enumerator {
                    do {
                        let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                        if fileAttributes.isRegularFile == true && fileURL.pathExtension == "swift" {
                            inputFiles.append(PackagePlugin.Path(fileURL.path))
                        }
                    } catch { print(error, fileURL) }
                }
            }
        }
    }
    
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        
        guard let target = target as? SwiftSourceModuleTarget else {
            return []
        }

        let tool = try context.tool(named: "Transom")
        
        // Find all .swift files in our target and all of our target's dependencies, add them as input files
        var rootFiles: [PackagePlugin.Path] = []
        let dependencyFiles: [PackagePlugin.Path] = []
        
        gatherSwiftInputFiles(targets: [target],
                              inputFiles: &rootFiles)
        //gatherSwiftInputFiles(targets: target.recursiveTargetDependencies,
        //                      inputFiles: &dependencyFiles)
        
        let allInputFiles = rootFiles + dependencyFiles
        
        print(allInputFiles)
        
        let inputFilesFilePath = context.pluginWorkDirectory.string + "/inputFiles.txt"
        var inputFilesString = ""
        
        for file in rootFiles {
            inputFilesString.append("\(file)\n")
        }
        for file in dependencyFiles {
            inputFilesString.append("+\(file)\n")
        }
        
        try! inputFilesString.write(toFile: inputFilesFilePath, atomically: false, encoding: .utf8)
        
        let outputFilePath = context.pluginWorkDirectory.string
        
        var allOutputFiles = allInputFiles.map { outputFilePath + "/" + URL(fileURLWithPath: $0.string).deletingPathExtension().appendingPathExtension("kt").lastPathComponent }
        
        allOutputFiles.append(outputFilePath + "/canary.swift")
                
        if shouldProcess(inputs: allInputFiles.map { $0.string },
                         outputs: allOutputFiles) {
            return [
                .buildCommand(
                    displayName: "Transom Plugin - generating Kotlin...",
                    executable: tool.path,
                    arguments: [
                        inputFilesFilePath,
                        outputFilePath
                    ],
                    inputFiles: allInputFiles,
                    outputFiles: allOutputFiles.map { PackagePlugin.Path($0) }
                )
            ]
        }
        
        return [
            .buildCommand(
                displayName: "Transom Plugin - skipping...",
                executable: tool.path,
                arguments: [ "skip", outputFilePath ],
                inputFiles: allInputFiles,
                outputFiles: allOutputFiles.map { PackagePlugin.Path($0) }
            )
        ]
    }
}
/*

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

fileprivate func git() -> String? {
    do {
        let path = pathFor(executable: "git")
                    
        let repoPath = FileManager.default.currentDirectoryPath
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = [
            "-C",
            repoPath,
            "describe"
        ]
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        task.standardInput = inputPipe
        task.standardOutput = outputPipe
        task.standardError = nil
        try task.run()
        
        DispatchQueue.global(qos: .userInitiated).async {
            inputPipe.fileHandleForWriting.write(Data())
            inputPipe.fileHandleForWriting.closeFile()
        }
        let tagData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                        
        if let tagString = String(data: tagData, encoding: .utf8) {
            if tagString.hasPrefix("v") && tagString.components(separatedBy: ".").count == 3 {
                return tagString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            } else {
                print("warning: git describe did not return a valid semver, got \(tagString) instead")
            }
        }
        
        return nil
    } catch {
        print("warning: failed to retrieve semver from git")
        return nil
    }
}
*/
