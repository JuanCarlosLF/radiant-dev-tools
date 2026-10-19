package com.jclopez.radiant.devtools.cli

import kotlin.system.exitProcess

suspend fun main(args: Array<String>) {
    exitProcess(runCli(args.toList()))
}
