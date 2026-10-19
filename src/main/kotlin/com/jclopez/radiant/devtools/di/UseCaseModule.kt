package com.jclopez.radiant.devtools.di

import com.jclopez.radiant.devtools.application.scan.report.GetScanReport
import org.koin.dsl.module

val useCaseModule = module {
    single<GetScanReport> { GetScanReport(get()) }
}
