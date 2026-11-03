package com.jclopez.radiant.devtools.adapter.scan

import com.jclopez.radiant.devtools.adapter.scanner.ScanResultReader
import com.jclopez.radiant.devtools.application.scan.ScanResultsRepository
import com.jclopez.radiant.devtools.application.scan.ScanResultsNotFound
import com.jclopez.radiant.devtools.contract.scanner.ScanResults
import java.nio.file.NoSuchFileException
import java.nio.file.Path
import kotlin.io.path.Path

class JsonScanResultsRepository(
    private val reader: ScanResultReader,
    private val path: Path = Path("artifacts/scan-results.json"),
) : ScanResultsRepository {
    override suspend fun getScanResults(): ScanResults = try {
        reader.read(path)
    } catch (cause: NoSuchFileException) {
        throw ScanResultsNotFound(path.toAbsolutePath().normalize(), cause)
    }
}
