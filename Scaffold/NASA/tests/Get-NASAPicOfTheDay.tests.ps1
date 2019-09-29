$Here = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ThisModule = Split-Path -Leaf $Here

if ($PSVersionTable.PSEdition -eq "Desktop") {
    $PathDivider = "\"
}
elseif ($PSVersionTable.PSEdition -eq "Core") {

    if (($isMACOS) -or ($isLinux)) {
        $PathDivider = "/"
    }
    else {
        $PathDivider = "\"
    }
}


Get-Module -ListAvailable -Name $ThisModule -All | Remove-Module -Force -ErrorAction Ignore
Import-Module -Name "$Here$PathDivider$ThisModule.psd1" -Force -ErrorAction Stop

Describe -Name 'Get-NASAPicOfTheDay Unit Tests' -Tags 'Unit'{

    InModuleScope $ThisModule {

        $mockeddata = @'
<Objs Version="1.1.0.1" xmlns="http://schemas.microsoft.com/powershell/2004/04">
  <Obj RefId="0">
    <TN RefId="0">
      <T>System.Management.Automation.PSCustomObject</T>
      <T>System.Object</T>
    </TN>
    <MS>
      <S N="date">2019-09-10</S>
      <S N="explanation">What color is Pluto, really? It took some effort to figure out.  Even given all of the images sent back to Earth when the robotic New Horizons spacecraft sped past Pluto in 2015, processing these multi-spectral frames to approximate what the human eye would see was challenging. The result featured here, released three years after the raw data was acquired by New Horizons, is the highest resolution true color image of Pluto ever taken. Visible in the image is the light-colored, heart-shaped, Tombaugh Regio, with the unexpectedly smooth Sputnik Planitia, made of frozen nitrogen, filling its western lobe. New Horizons found the dwarf-planet to have a surprisingly complex surface composed of many regions having perceptibly different hues.  In total, though, Pluto is mostly brown, with much of its muted color originating from small amounts of surface methane energized by ultraviolet light from the Sun.</S>
      <S N="hdurl">https://apod.nasa.gov/apod/image/1909/PlutoTrueColor_NewHorizons_8000.jpg</S>
      <S N="media_type">image</S>
      <S N="service_version">v1</S>
      <S N="title">Pluto in True Color</S>
      <S N="url">https://apod.nasa.gov/apod/image/1909/PlutoTrueColor_NewHorizons_960.jpg</S>
    </MS>
  </Obj>
</Objs>
'@
        Context -Name 'Unit Testing for POTD Data' {

            $picdata = [System.Management.Automation.PSSerializer]::DeserializeAsList($mockeddata)

            $testdata = $picdata[0]

            It "The POTD Title [$($testdata.title)] should not be null" {
                $testdata.title | Should not BeNullOrEmpty
            }

            It "Should properly describe the POTD" {
                $testdata.explanation | Should not BeNullOrEmpty
            }

            It "Should have a properly formed URL" {
                [bool]([system.uri]::IsWellFormedUriString($testdata.hdurl, [System.UriKind]::Absolute)) | Should be True
            }


            #It "Image $imgFileName should exist in download list" {
            #    [bool]($imgFileName -in $downloadedImages) | Should Be $true
            #}
        }

    }



}


Describe -Name 'Get-NASAPicOfTheDay Acceptance Tests' -Tags 'Acceptance' {

    InModuleScope $ThisModule {

        $token = $env:Nasakey
        $picdata = Get-NASAData -url "https://api.nasa.gov/planetary/apod?api_key=$token"
        Write-Debug "here is the picdata [$picdata]"

        Context -Name "The APOD data object should have all the properties"{

            It -Name "The Picture data should not be null or empty" {
                $picdata | Should not BeNullOrEmpty
            }

            $properties = ('date', 'explanation', 'hdurl', 'media_type', 'service_version', 'title', 'url' )

            foreach($property in $properties){

                It -Name "The picture data should have a property of $property"{
                    [bool]($picdata.PSObject.Properties.Name -match $property) | Should Be $true
                }

            }

            It "The POTD Title [$($picdata.title)] should not be null" {
                $picdata.title | Should not BeNullOrEmpty
            }

            It "The explanation field should properly describe the POTD" {
                $picdata.explanation | Should not BeNullOrEmpty
            }

            It "The URL should be properly formed" {
                [bool]([system.uri]::IsWellFormedUriString($picdata.hdurl, [System.UriKind]::Absolute)) | Should be True
            }

            It "Should download a valid image file"{

                # create a unique temp folder to download the new file to.
                $parent = [system.io.path]::GetTempPath()
                [string]$name = [System.Guid]::NewGuid()
                $subdir = New-Item -ItemType Directory -Path (Join-Path $parent $name)
                $tempfolder = $subdir.Fullname

                $filename = $picdata.hdurl.Split("/")[-1]
                $Outfile = $tempfolder + $PathDivider + $filename
                Invoke-WebRequest -Uri $picdata.hdurl -OutFile $Outfile

                $imagedata = Get-ItemProperty -Path $Outfile
                $Image = [system.drawing.image]::fromfile($outfile)

                $imageprops = $Image.PropertyItems
                # Id 513 and 514 are JPG props. Does that match the downloaded file?
                #

                if($imageprops.id -contains 513 ){
                    Write-Host "Success" -ForegroundColor Green
                }

            }

        }

    }

}