package com.jclopez.radiant.devtools.contract.scanner

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class TutorStation(
    val id: String,
    val name: String,
    val offers: List<TutorOffer> = emptyList(),
)

@Serializable
data class TutorOffer(
    val move: String,
    val cost: TutorCost = TutorCost(),
)

@Serializable
data class TutorCost(
    @SerialName("green_shard")
    val greenShard: Int = 0,
    @SerialName("red_shard")
    val redShard: Int = 0,
    @SerialName("blue_shard")
    val blueShard: Int = 0,
    @SerialName("yellow_shard")
    val yellowShard: Int = 0,
)
