package com.jclopez.radiant.devtools.di

import org.koin.core.module.Module
import org.koin.dsl.module

fun appModule(presentation: Module) = module {
    includes(dataModule, useCaseModule, presentation)
}
