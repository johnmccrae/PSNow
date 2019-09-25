<#
    .SYNOPSIS

    Gets a list of Near Earth Orbit objects from NASA

    .DESCRIPTION

    This function connects to NASA via Rest API and pulls back list of objects that are going to pass-by close to earth. The function then outputs
    the current numvber of objects being tracked today and some details on each of them.

    .INPUTS

    None.

    .OUTPUTS

    System.String. The function returns a string containing the number of objects being monitored by NASA in the a 24 hour window. It also displays
    a PSCustomObject that has relevant details on each of the objects being monitored.

    .EXAMPLE

    PS> Get-NASANearEarthObjects
    NASA is tracking a total of [20] Near Earth objects today: Sunday, September 8, 2019


    Name                   : 456938 (2007 YV56)
    ID                     : 2456938
    Max Diameter in meters : 375.01

    .LINK

    https://api.nasa.gov/index.html

    # Near Earth Object Web Service - NeoWs - Feed
    # retrieve a list of objects based on their closest approach date to Earth
    # Date format - YYYY-MM-DD
    # $url = 'https://api.nasa.gov/neo/rest/v1/feed?start_date=START_DATE&end_date=END_DATE&api_key=Demo_key'
    # Lookup a specific object
    # $url = 'https://api.nasa.gov/neo/rest/v1/neo/3542519?api_key=DEMO_KEY'
    # Browse the asteroid data set
    # $url = 'https://api.nasa.gov/neo/rest/v1/neo/browse?api_key=DEMO_KEY'

#>
function Get-NASANearEarthObjects {

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    [CmdletBinding()]
    param(
        [Parameter()]
        [System.String]
        $token = $env:NasaKey,
        [Parameter()]
        [System.String]
        $url,
        [Parameter()]
        [System.DateTime]
        $startdate = (get-date (get-date).addDays(-1) -Format "yyyy-MM-dd"),
        [Parameter()]
        [System.DateTime]
        $enddate = (Get-Date -format "yyyy-MM-dd")
    )
    begin {

    }
    process {

        $nasa_data = Get-NasaData -url "https://api.nasa.gov/neo/rest/v1/feed?start_date=$yesterday&end_date=$today&api_key=$token"

        Write-Output "`n"
        Write-Host -NoNewline "NASA is tracking a total of [$($nasa_data.element_count)] Near Earth objects today: $(Get-Date -format D)"
        Write-Output "`n"

        $objects = $nasa_data.near_earth_objects.$today
        $objects += $nasa_data.near_earth_objects.$yesterday

        foreach ($object in $objects) {

            $approachdata = $object.close_approach_data
            $miles = '{0:N2}' -f [double]::Parse($approachdata[0].miss_distance.miles)
            $meters = '{0:N2}' -f $object.estimated_diameter.meters.estimated_diameter_max

            if ($object.is_potentially_hazardous_asteroid -eq $true) {
                $isitdangerous = "Yes"
            }
            else {
                $isitdangerous = "No"
            }

            [PSCustomObject]@{
                Name                     = $object.name
                ID                       = $object.id
                'Max Diameter in meters' = $meters
                'Is it Dangerous?'       = $isitdangerous
                'Flyby Date'             = $approachdata[0].close_approach_date
                'Miss Distance in Miles' = $miles
            }
        }
    }
}
