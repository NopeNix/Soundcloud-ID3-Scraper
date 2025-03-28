[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [String]
    $MusicPath,

    [Parameter(Mandatory = $true)]
    [String]
    $SoundcloudClient_ID
)

Write-Host ("Loading Tracklist...") -ForegroundColor Blue
try {
    $Tracklist = Get-ChildItem -Path $MusicPath
    $Tracklist | ForEach-Object {
        $_ | Add-Member -NotePropertyName "TrackID" -NotePropertyValue (($_.Name).split("-")[-1]).split(".")[0]
    }
    Write-Host (" -> Done! " + $Tracklist.count + " ID's loaded") -ForegroundColor Green
}
catch {
    Write-Host (" -> ERROR: " + $_.Exception.Message) -ForegroundColor Red
    Exit 1
}
Write-Host ""


Write-Host ("Getting Track Infos from Soundcloud...") -ForegroundColor Blue
New-Item -ItemType Directory -Path ($PSScriptRoot + "/img/") -ErrorAction SilentlyContinue
$Tracklist | ForEach-Object -Parallel {
    $CurrentTrack = $_
    try {
        $Header = @{
            accept = "application/json"
        }
        $TrackInfo = Invoke-RestMethod -Uri ("https://api-v2.soundcloud.com/tracks/" + $_.TrackID + "?client_id=" + $using:SoundcloudClient_ID) -Headers $Header
        $_ | Add-Member -NotePropertyName "TrackInfo" -NotePropertyValue $TrackInfo -Force
        if ($null -ne $_.Trackinfo.artwork_url -and $_.Trackinfo.artwork_url -ne "") {
            Invoke-WebRequest -Uri ($_.Trackinfo.artwork_url.Replace("-large.jpg","-t500x500.jpg")) -OutFile ($using:PSScriptRoot + "/img/" + $_.TrackID + ".jpg")
        }
    }
    catch {
        Write-Host (" -> ERROR: Could not get track info for " + $CurrentTrack.Name + " : " + $_.Exception.Message) -ForegroundColor Red
    }
} -ThrottleLimit 20
Write-Host (" -> Done! " + $Tracklist.TrackInfo.count + "/" + $Tracklist.count + " Trackinfos Loaded") -ForegroundColor Green
Write-Host ""


Write-Host ("Preparing to write Tags..") -ForegroundColor Blue
try {
    # Load the DLL
    Add-Type -Path ($PSScriptRoot + "/TagLibSharp.dll") -ErrorAction Stop
    Write-Host " -> TagLib# loaded successfully!" -ForegroundColor Green
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""


Write-Host ("Adding ID3 Tags to Tracks...") -ForegroundColor Blue
$Tracklist | ForEach-Object -Parallel {
    if ($null -ne $_.Trackinfo -or $_.Trackinfo -ne "") {
        $CurrentTrack = $_
        try {
            # Open the MP3 file using TagLib
            $file = [TagLib.File]::Create($_.FullName)

            # Write basic ID3 tags
            $file.Tag.Title = $_.TrackInfo.title
            #$file.Tag.Album = $_.TrackInfo.title
            $file.Tag.Artists = $_.TrackInfo.user.username
            $file.Tag.Year = $_.TrackInfo.display_date.year
            $file.Tag.Genres = $_.TrackInfo.genre
            #$file.Tag.Track = 1
            #$file.Tag.Comment = "This is a comment."
            if ($null -ne $_.Trackinfo.artwork_url -and $_.Trackinfo.artwork_url -ne "") {
                # Load the image file and create a Picture object
                $imageData = [System.IO.File]::ReadAllBytes(($using:PSScriptRoot + "/img/" + $_.TrackID + ".jpg"))
                $picture = New-Object TagLib.Picture
                $picture.Data = $imageData
                $picture.MimeType = "image/jpeg"  # Change to "image/png" if using a PNG
                $picture.Type = [TagLib.PictureType]::FrontCover  # Type of picture (e.g., Front Cover)

                # Clear existing pictures (optional) and add the new one
                $file.Tag.Pictures = @()
                $file.Tag.Pictures += $picture
            }

            # Save the changes
            $file.Save()

            # Clean up
            $file.Dispose()
            Write-Host (" -> OK: '" + $CurrentTrack.Name + "'")-ForegroundColor Green
        }
        catch {
            Write-Host (" -> Error for track '" + $CurrentTrack.Name + "': " + $_.Exception.Message )-ForegroundColor Red
        }
    }
    else {
        Write-Host (" -> Skipped " + $_.Name + "because not ID3 Tags available") -ForegroundColor Yellow
    }
} -ThrottleLimit 10