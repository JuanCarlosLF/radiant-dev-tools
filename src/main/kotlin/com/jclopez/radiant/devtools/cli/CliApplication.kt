package com.jclopez.radiant.devtools.cli

import java.io.PrintStream

class CliApplication(
    commands: List<CliCommand>,
    private val stdout: PrintStream,
    private val stderr: PrintStream,
) {
    init {
        val duplicateNames = commands
            .groupingBy { it.name }
            .eachCount()
            .filterValues { count -> count > 1 }
            .keys
            .sorted()
        check(duplicateNames.isEmpty()) {
            "Duplicate CLI command names: ${duplicateNames.joinToString(", ")}"
        }
    }

    private val commandsByName = commands.associateBy { it.name }

    suspend fun run(args: List<String>): Int {
        if (args.isEmpty()) {
            return usageError("a command is required")
        }
        if (args == listOf("--help")) {
            printHelp()
            return 0
        }

        val command = commandsByName[args.first()]
            ?: return usageError("unknown command '${args.first()}'")
        return command.execute(args.drop(1))
    }

    private fun usageError(message: String): Int {
        stderr.println("Usage error: $message")
        printHelp(stderr)
        return 2
    }

    private fun printHelp(stream: PrintStream = stdout) {
        stream.println("Usage: <command> [options]")
        stream.println("Commands:")
        commandsByName.values.forEach { command ->
            stream.println("  ${command.usage}")
        }
        stream.println("Use --help for this help.")
    }
}
