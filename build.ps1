# Versions to build
$loaderVersions = @(
    "0.20.1","0.20.0",
    "0.19.5","0.19.4","0.19.3","0.19.2", "0.19.1", "0.19.0",
    "0.18.6","0.18.5","0.18.4","0.18.3","0.18.2","0.18.1","0.18.0",
    "0.17.3","0.17.2","0.17.1","0.17.0",
    "0.16.14","0.16.13","0.16.12","0.16.11","0.16.10","0.16.9","0.16.8","0.16.7","0.16.6","0.16.5","0.16.4","0.16.3","0.16.2","0.16.1","0.16.0",
    "0.15.11","0.15.10","0.15.9","0.15.8","0.15.7","0.15.6","0.15.5","0.15.4","0.15.3","0.15.2","0.15.1","0.15.0"
) | Sort-Object { [version]$_ }
$gameVersions = @(
    "26.3",
    "26.2",
    "26.1.2", "26.1.1", "26.1",
    "1.21.11", "1.21.10", "1.21.9", "1.21.8", "1.21.7", "1.21.6", "1.21.5", "1.21.4", "1.21.3", "1.21.2", "1.21.1", "1.21",
    "1.20.6", "1.20.5", "1.20.4", "1.20.3", "1.20.2", "1.20.1", "1.20",
    "1.19.4", "1.19.3", "1.19.2", "1.19.1", "1.19",
    "1.18.2", "1.18.1", "1.18",
    "1.17.1", "1.17",
    "1.16.5", "1.16.4", "1.16.3", "1.16.2", "1.16.1", "1.16",
    "1.15.2", "1.15.1", "1.15",
    "1.14.4", "1.14.3", "1.14.2", "1.14.1", "1.14"
)
$publishToModrinth = $false

function Get-LatestModrinthVersion {
    try {
        $projectResponse = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/project/OoMgWV72" `
            -Method Get -Headers @{ "User-Agent" = "FabricLoader-BuildScript/1.0" }

        if ($null -eq $projectResponse -or $null -eq $projectResponse.versions -or @($projectResponse.versions).Count -eq 0) {
            return $null
        }

        $latestVersionId = $projectResponse.versions[-1]

        $versionResponse = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/project/OoMgWV72/version/$latestVersionId" `
            -Method Get -Headers @{ "User-Agent" = "FabricLoader-BuildScript/1.0" }

        if ($null -eq $versionResponse) {
            return $null
        }

        return $versionResponse.version_number
    }
    catch {
        Write-Host "Warning: Could not fetch latest version from Modrinth: $_"
        return $null
    }
}

function Get-NextBuildVersion {
    param([string]$BaseVersion)

    $latestVersion = $cachedLatestVersion

    if ($null -eq $latestVersion) {
        return "$BaseVersion-1"
    }

    $buildNumber = 1

    if ($latestVersion -match "^.+-(\d+)$") {
        $buildNumber = [int]$matches[1]
    }

    $nextBuild = $buildNumber + 1
    return "$BaseVersion-$nextBuild"
}

function Publish-ToModrinth {
    param(
        [string]$VersionString,
        [string]$JarPath
    )

    if ([string]::IsNullOrEmpty($env:MODRINTH_TOKEN)) {
        Write-Host "Warning: MODRINTH_TOKEN environment variable not set. Skipping Modrinth publish."
        return $false
    }

    try {
        $jarFile = Get-Item $JarPath -ErrorAction Stop
        $jarName = $jarFile.Name

        # Prepare multipart form data
        $boundary = [guid]::NewGuid().ToString()
        $encoding = [System.Text.Encoding]::UTF8
        $memoryStream = [System.IO.MemoryStream]::new()

        # Build JSON data object
        $versionData = @{
            project_id = "OoMgWV72"
            name = $VersionString
            version_number = $VersionString
            changelog = ""
            loaders = @("fabric", "quilt")
            game_versions = $gameVersions
            dependencies = @()
            version_type = "release"
            featured = $false
            file_parts = @("file")
        } | ConvertTo-Json -Compress

        # Helper function to write string to stream
        function Write-ToStream {
            param([System.IO.MemoryStream]$stream, [string]$text)
            $bytes = $encoding.GetBytes($text)
            $stream.Write($bytes, 0, $bytes.Length)
        }

        # Add data field
        Write-ToStream $memoryStream "--$boundary`r`n"
        Write-ToStream $memoryStream "Content-Disposition: form-data; name=`"data`"`r`n`r`n"
        Write-ToStream $memoryStream $versionData
        Write-ToStream $memoryStream "`r`n"

        # Add file field
        Write-ToStream $memoryStream "--$boundary`r`n"
        Write-ToStream $memoryStream "Content-Disposition: form-data; name=`"file`"; filename=`"$jarName`"`r`n"
        Write-ToStream $memoryStream "Content-Type: application/java-archive`r`n`r`n"

        # Append binary file content
        $fileBytes = [System.IO.File]::ReadAllBytes($JarPath)
        $memoryStream.Write($fileBytes, 0, $fileBytes.Length)

        # Add closing boundary
        Write-ToStream $memoryStream "`r`n--$boundary--`r`n"

        $bodyBytes = $memoryStream.ToArray()
        $memoryStream.Close()

        Write-Host "Publishing $VersionString to Modrinth..."

        $uploadUrl = "https://api.modrinth.com/v2/version"
        $headers = @{
            "Authorization" = $env:MODRINTH_TOKEN
        }

        $response = Invoke-WebRequest -Uri $uploadUrl `
            -Method Post `
            -Headers $headers `
            -ContentType "multipart/form-data; boundary=$boundary" `
            -Body $bodyBytes `
            -ErrorAction Stop

        Write-Host "  Published successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "  Failed to publish: $($_.Exception.Message)" -ForegroundColor Red
        try {
            if ($_ -and $_.ErrorDetails -and $_.ErrorDetails.Message) {
                Write-Host "    Error: $($_.ErrorDetails.Message)" -ForegroundColor Gray
            }
        }
        catch { }
        return $false
    }
}

# Fetch latest version once and cache it
$cachedLatestVersion = Get-LatestModrinthVersion

# Run clean once
Write-Host "Running gradlew clean..."
& ./gradlew clean
if ($LASTEXITCODE -ne 0)
{
    throw "gradlew clean failed"
}

foreach ($version in $loaderVersions)
{
    Write-Host "Processing version $version"

    # Get the next build version for Modrinth
    $publishVersion = Get-NextBuildVersion -BaseVersion $version
    Write-Host "Will publish as: $publishVersion"

    # Read gradle.properties
    $lines = Get-Content ".\gradle.properties"

    if ($lines.Count -lt 11)
    {
        throw "gradle.properties does not have at least 11 lines"
    }

    # Line 11 (index 10) replacement - use base version only
    $lines[10] = "mod_version=$version"

    # Write back file
    Set-Content ".\gradle.properties" $lines -Encoding UTF8

    # Run build
    Write-Host "Building version $version"
    & ./gradlew build
    if ($LASTEXITCODE -ne 0)
    {
        throw "Build failed for version $version"
    }

    # Find the built jar file (exclude sources and javadoc)
    if (-not (Test-Path "build/libs")) {
        Write-Host "Warning: build/libs directory not found for version $version"
        $jarPath = $null
    }
    else {
        $jarPath = Get-ChildItem -Path "build/libs" -Filter "loader-*.jar" | Where-Object { $_.Name -notmatch "(sources|javadoc)" } | Select-Object -Last 1
    }

    if ($null -eq $jarPath) {
        Write-Host "Warning: Could not find built jar file for version $version"
    }
    else {
        # Rename jar file to include build suffix
        $oldPath = $jarPath.FullName
        $newPath = $oldPath -replace "loader-$version\.jar$", "loader-$publishVersion.jar"

        if ($oldPath -ne $newPath) {
            Rename-Item -Path $oldPath -NewName (Split-Path $newPath -Leaf) -Force
            Write-Host "Renamed: $(Split-Path $oldPath -Leaf) -> $(Split-Path $newPath -Leaf)"
            $jarPath = Get-Item $newPath
        }

        if ($publishToModrinth) {
            # Publish to Modrinth
            Publish-ToModrinth -VersionString $publishVersion -JarPath $jarPath.FullName
        }
        else {
            Write-Host "Skipping Modrinth publish (publishToModrinth = false)"
        }
    }

    Write-Host "Completed version $publishVersion`n"
}
