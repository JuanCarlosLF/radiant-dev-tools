package com.jclopez.radiant.devtools.application.scan

import com.jclopez.radiant.devtools.contract.scanner.ScanResults

interface ScanResultsRepository {
    suspend fun getScanResults(): ScanResults
}
