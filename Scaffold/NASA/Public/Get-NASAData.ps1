<#
    .SYNOPSIS

    Gets the Astronomy Pic Of the Day from NASA

    .DESCRIPTION

    This function connects to NASA via Rest API and pulls the Astronomy Pic Of the Day and displays it in your browser along with displaying
    the description of what you are looking at in your PowerShell window

    .INPUTS

    None.

    .OUTPUTS

    System.String. A String object containing a usually verbose description of the celestial body now open in your browser window.

    .OUTPUTS

    System.Object. A jpg or png file containing an image of today's picture of the day

    .EXAMPLE

    PS> Get-NASAPicOfTheDay
    Perijove 11: Passing Jupiter
    --------------------------------------------------------

    Here comes Jupiter! NASA's robotic spacecraft Juno is continuing on its 53-day, highly-elongated orbits around our
    Solar System's largest planet.  The featured video is from perijove 11 in early 2018, the eleventh time Juno has passed
    near Jupiter since it arrived in mid-2016.  This time-lapse, color-enhanced movie covers about four hours and morphs
    between 36 JunoCam images. The video begins with Jupiter rising as Juno approaches from the north. As Juno reaches its
    closest view -- from about 3,500 kilometers over Jupiter's cloud tops -- the spacecraft captures the great planet in
    tremendous detail. Juno passes light zones and dark belt of clouds that circle the planet, as well as numerous swirling
    circular storms, many of which are larger than hurricanes on Earth.  After the perijove, Jupiter recedes into the
    distance, now displaying the unusual clouds that appear over Jupiter's south.  To get desired science data, Juno swoops
    so close to Jupiter that its instruments are exposed to very high levels of radiation.

    .LINK

    https://api.nasa.gov/index.html


#>
function Get-NASAData {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    [CmdletBinding()]
    param(
        [Parameter()]
        [System.String]
        $token = $env:NasaKey,
        [Parameter(Mandatory=$true)]
        [System.String]
        $url = "",
        [Parameter(Mandatory=$false)]
        [System.Collections.Hashtable]
        $parameters
    )
    begin {
        #process parameters first, build the url with them, then invoke the restmethod
        $nasa_data = Invoke-RestMethod -Uri $url
        return $nasa_data
    }


}