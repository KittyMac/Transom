import Foundation
import PackagePlugin

func binaryTool(named toolName: String) -> String {
    var osName = "focal"
    var swiftVersion = "unknown"
    
    #if os(Windows)
    osName = "windows"
    #else
    if let osFile = try? String(contentsOfFile: "/etc/os-release") {
        if osFile.contains("Amazon Linux") {
            osName = "amazonlinux2"
        }
        if osFile.contains("Fedora Linux 37") {
            osName = "fedora37"
        }
        if osFile.contains("Fedora Linux 38") {
            osName = "fedora38"
        }
    }
    #endif
    
#if swift(>=5.9.2)
    swiftVersion = "592"
#elseif swift(>=5.7.3)
    swiftVersion = "573"
#elseif swift(>=5.7.1)
    swiftVersion = "571"
#endif

    return "\(toolName)-\(osName)-\(swiftVersion)"
}

@main struct TransomPlugin: BuildToolPlugin {
        
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
        
        let toolName = "TransomTool"
        let binaryToolName = binaryTool(named: toolName)
        guard let tool = (try? context.tool(named: binaryToolName)) ?? (try? context.tool(named: toolName)) else {
            fatalError("TransomTool unable to load \(binaryToolName)")
        }
        
        // Find all .swift files in our target and all of our target's dependencies, add them as input files
        var rootFiles: [PackagePlugin.Path] = []
        let dependencyFiles: [PackagePlugin.Path] = []
        
        gatherSwiftInputFiles(targets: [target],
                              inputFiles: &rootFiles)
        //gatherSwiftInputFiles(targets: target.recursiveTargetDependencies,
        //                      inputFiles: &dependencyFiles)
        
        
        let allInputFiles = rootFiles + dependencyFiles
                
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
        
        var allOutputFiles: [String] = []
        //allOutputFiles += allInputFiles.map { outputFilePath + "/" + URL(fileURLWithPath: $0.string).deletingPathExtension().appendingPathExtension("kt").lastPathComponent }
        allOutputFiles.append(outputFilePath + "/canary.swift")
        
        return [
            .buildCommand(
                displayName: "Transom Plugin - generating code...",
                executable: tool.path,
                arguments: [
                    "--kotlin",
                    "--typescript",
                    inputFilesFilePath,
                    outputFilePath
                ],
                inputFiles: allInputFiles,
                outputFiles: allOutputFiles.map { PackagePlugin.Path($0) }
            )
        ]
    }
}

