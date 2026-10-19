package com.jclopez.radiant.devtools.cli.scan

import com.jclopez.radiant.devtools.adapter.scanner.UnsupportedScanSchemaException
import com.jclopez.radiant.devtools.application.scan.MapId
import com.jclopez.radiant.devtools.application.scan.report.GetScanReport
import com.jclopez.radiant.devtools.application.scan.report.ScanReport
import com.jclopez.radiant.devtools.contract.scanner.ScanStatus
import com.jclopez.radiant.devtools.cli.CliCommand
import java.io.IOException
import java.io.PrintStream
import kotlinx.serialization.SerializationException

class ScanCommand(
    private val getScanReport: GetScanReport,
    private val stdout: PrintStream,
    private val stderr: PrintStream,
) : CliCommand {
    override val name = "scan"
    override val usage = "scan [--map <positive integer>]"

    override suspend fun execute(args: List<String>): Int {
        val mapId = try {
            parseArguments(args)
        } catch (error: UsageException) {
            stderr.println("Usage error: ${error.message}")
            stderr.println("Usage: $usage")
            return 2
        }

        val report = try {
            getScanReport(mapId)
        } catch (error: IOException) {
            stderr.println("I/O error: ${error.message ?: "Unable to read scan results"}")
            return 3
        } catch (error: SerializationException) {
            stderr.println("Data error: ${error.message ?: "Invalid scan results JSON"}")
            return 1
        } catch (error: UnsupportedScanSchemaException) {
            stderr.println("Data error: ${error.message ?: "Unsupported scan results"}")
            return 1
        }

        stdout.println(ScanReportRenderer.render(report))
        return if (report.status == ScanStatus.FAILED) 1 else 0
    }

    private fun parseArguments(args: List<String>): MapId? {
        if (args.isEmpty()) return null
        if (args.size != 2 || args[0] != "--map") {
            throw UsageException("expected at most one '--map <positive integer>' option")
        }

        val value = args[1].toIntOrNull()
            ?: throw UsageException("map ID must be a positive integer")
        return try {
            MapId(value)
        } catch (error: IllegalArgumentException) {
            throw UsageException("map ID must be a positive integer")
        }
    }

    private class UsageException(message: String) : RuntimeException(message)
}
