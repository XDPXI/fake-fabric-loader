# Versions to build
$versions = @(
    "0.18.4","0.18.3","0.18.2","0.18.1","0.18.0",
    "0.17.3","0.17.2","0.17.1","0.17.0",
    "0.16.14","0.16.13","0.16.12","0.16.11","0.16.10",
    "0.16.9","0.16.8","0.16.7","0.16.6","0.16.5",
    "0.16.4","0.16.3","0.16.2","0.16.1","0.16.0",
    "0.15.11","0.15.10","0.15.9","0.15.8","0.15.7",
    "0.15.6","0.15.5","0.15.4","0.15.3","0.15.2",
    "0.15.1","0.15.0"
)

$gradlePropsPath = "gradle.properties"

# Run clean once
Write-Host "Running gradlew clean..."
& ./gradlew clean
if ($LASTEXITCODE -ne 0) {
    throw "gradlew clean failed"
}

foreach ($version in $versions) {
    Write-Host "Building version $version"

    # Read gradle.properties
    $lines = Get-Content $gradlePropsPath

    if ($lines.Count -lt 9) {
        throw "gradle.properties does not have at least 9 lines"
    }

    # Line 9 (index 8) replacement
    $lines[8] = "mod_version=$version"

    # Write back file
    Set-Content $gradlePropsPath $lines -Encoding UTF8

    # Run build
    & ./gradlew build
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed for version $version"
    }
}

Write-Host "All builds completed successfully."
