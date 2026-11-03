package com.jclopez.radiant.devtools.application.scan

import java.io.IOException
import java.nio.file.NoSuchFileException
import java.nio.file.Path

class ScanResultsNotFound(
    val path: Path,
    cause: NoSuchFileException,
) : IOException("Scan results were not found: $path", cause)
