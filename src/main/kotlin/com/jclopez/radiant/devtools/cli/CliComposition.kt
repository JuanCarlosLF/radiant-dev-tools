package com.jclopez.radiant.devtools.cli

import com.jclopez.radiant.devtools.cli.di.presentationModule
import com.jclopez.radiant.devtools.di.appModule
import java.io.PrintStream
import org.koin.dsl.koinApplication

suspend fun runCli(
    args: List<String>,
    stdout: PrintStream = System.out,
    stderr: PrintStream = System.err,
): Int {
    val application = koinApplication {
        modules(appModule(presentationModule(stdout, stderr)))
    }
    return try {
        application.koin.get<CliApplication>().run(args)
    } finally {
        application.close()
    }
}
