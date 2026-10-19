package com.jclopez.radiant.devtools.cli.di

import com.jclopez.radiant.devtools.cli.CliApplication
import com.jclopez.radiant.devtools.cli.CliCommand
import com.jclopez.radiant.devtools.cli.scan.ScanCommand
import java.io.PrintStream
import org.koin.core.qualifier.named
import org.koin.dsl.module

private const val CLI_STDOUT = "cli.stdout"
private const val CLI_STDERR = "cli.stderr"

fun presentationModule(stdout: PrintStream, stderr: PrintStream) = module {
    single<PrintStream>(named(CLI_STDOUT)) { stdout }
    single<PrintStream>(named(CLI_STDERR)) { stderr }
    single<CliCommand>(named("scan")) {
        ScanCommand(get(), get(named(CLI_STDOUT)), get(named(CLI_STDERR)))
    }
    single {
        CliApplication(
            commands = getAll<CliCommand>(),
            stdout = get(named(CLI_STDOUT)),
            stderr = get(named(CLI_STDERR)),
        )
    }
}
