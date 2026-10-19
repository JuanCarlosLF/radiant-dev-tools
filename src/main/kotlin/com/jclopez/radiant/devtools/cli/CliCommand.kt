package com.jclopez.radiant.devtools.cli

interface CliCommand {
    val name: String
    val usage: String

    suspend fun execute(args: List<String>): Int
}
