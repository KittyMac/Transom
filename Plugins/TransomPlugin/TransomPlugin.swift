import Foundation
import PackagePlugin

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

        // Note: We want to load the right pre-compiled tool for the right OS
        // There are currently two tools:
        // TransomPluginTool-focal: supports macos and ubuntu-focal
        // TransomPluginTool-focal: supports macos and amazonlinux2
        //
        // When we are compiling to build the precompiled tools, only the
        // default ( TransomPluginTool-focal ) is available.
        //
        // When we are running and want to use the pre-compiled tools, we look in
        // /etc/os-release (available on linux) to see what distro we are running
        // and to load the correct tool there.
        var tool = try? context.tool(named: "TransomTool-focal")
        
        if let osFile = try? String(contentsOfFile: "/etc/os-release") {
            if osFile.contains("Amazon Linux"),
               let osTool = try? context.tool(named: "TransomTool-amazonlinux2") {
                tool = osTool
            }
            if osFile.contains("Fedora Linux"),
               let osTool = try? context.tool(named: "TransomTool-fedora") {
                tool = osTool
            }
        }
        
        guard let tool = tool else {
            fatalError("TransomPlugin unable to load TransomTool")
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
}

