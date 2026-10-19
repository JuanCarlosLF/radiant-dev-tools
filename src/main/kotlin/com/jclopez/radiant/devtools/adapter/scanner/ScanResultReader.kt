package com.jclopez.radiant.devtools.adapter.scanner

import com.jclopez.radiant.devtools.contract.scanner.ScanResults
import kotlinx.serialization.json.Json
import java.nio.file.Path
import kotlin.io.path.Path
import kotlin.io.path.readText

private const val SCAN_RESULTS_PATH = "artifacts/scan-results.json"
private const val SUPPORTED_SCHEMA_VERSION = 1
private val JSON = Json { ignoreUnknownKeys = false }

class ScanResultReader() {

    suspend fun read(path: Path = Path(SCAN_RESULTS_PATH)): ScanResults {

        val json = path.readText()
        val results: ScanResults =
            JSON.decodeFromString(ScanResults.serializer(), json)

        if (results.schemaVersion != SUPPORTED_SCHEMA_VERSION) {
            throw UnsupportedScanSchemaException(results.schemaVersion)
        }

        return results
    }
}

class UnsupportedScanSchemaException(schemaVersion: Int) :
    IllegalStateException("Unsupported scan results schema version: $schemaVersion")
