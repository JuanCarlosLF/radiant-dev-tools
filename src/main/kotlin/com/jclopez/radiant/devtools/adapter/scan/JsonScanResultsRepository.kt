package com.jclopez.radiant.devtools.adapter.scan

import com.jclopez.radiant.devtools.adapter.scanner.ScanResultReader
import com.jclopez.radiant.devtools.application.scan.ScanResultsRepository
import com.jclopez.radiant.devtools.contract.scanner.ScanResults
import java.nio.file.Path
import kotlin.io.path.Path

class JsonScanResultsRepository(
    private val reader: ScanResultReader,
    private val path: Path = Path("artifacts/scan-results.json"),
) : ScanResultsRepository {
    override suspend fun getScanResults(): ScanResults =
        reader.read(path)
}
