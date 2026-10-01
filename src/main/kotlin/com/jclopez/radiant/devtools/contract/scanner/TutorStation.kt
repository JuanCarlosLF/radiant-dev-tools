package com.jclopez.radiant.devtools.contract.scanner

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class TutorStation(
    val id: String,
    val name: String,
    val offers: List<TutorOffer>,
)

@Serializable
data class TutorOffer(
    val move: String,
    val cost: TutorCost,
)

@Serializable
data class TutorCost(
    @SerialName("green_shard")
    val greenShard: Int,
    @SerialName("red_shard")
    val redShard: Int,
    @SerialName("blue_shard")
    val blueShard: Int,
    @SerialName("yellow_shard")
    val yellowShard: Int,
)
