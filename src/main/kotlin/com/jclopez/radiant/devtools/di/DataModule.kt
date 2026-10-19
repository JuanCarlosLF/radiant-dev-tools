package com.jclopez.radiant.devtools.di

import com.jclopez.radiant.devtools.adapter.scan.JsonScanResultsRepository
import com.jclopez.radiant.devtools.adapter.scanner.ScanResultReader
import com.jclopez.radiant.devtools.application.scan.ScanResultsRepository
import org.koin.dsl.module

val dataModule = module {
    single<ScanResultReader> { ScanResultReader() }
    single<ScanResultsRepository> { JsonScanResultsRepository(get()) }
}
