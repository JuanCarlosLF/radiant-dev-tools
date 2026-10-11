package com.jclopez.radiant.devtools.application.scan

@JvmInline
value class MapId(val value: Int) {
    init {
        require(value > 0) { "Map ID must be greater than zero" }
    }
}
