package com.jclopez.radiant.devtools.contract.scanner

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SoulFinding(
    @SerialName("stage_id")
    val stageId: String,
    val requires: List<String>,
    val source: Source,
    val notes: String,
)
