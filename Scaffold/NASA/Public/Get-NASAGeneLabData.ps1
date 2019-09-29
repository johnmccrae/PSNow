<#
    .SYNOPSIS

    Retrieves a Gene Lab project and lists others

    .DESCRIPTION

    NASA runs a number of mouse-based experiments on the International Space Station. This fuction returns the details of one of those experiments and points you to others you can poke around with.

    .INPUTS

    None.

    .OUTPUTS

    System.Object. The function returns a PSCustomObject containing the details for the specific study being polled via the URL used

    .EXAMPLE

    PS> Get-NASAGeneLabData
    This is a static link to a study of mice RNA in space studying the stress response. If you would like to examine other studies, please take a look here: https://api.nasa.gov/api.html#genelab

    Authoritative Source URL        : GSE82255
    links                           : {GPL13112, GPL16417}
    Flight Program                  :
    Mission                         : @{End Date=0000000000; Start Date=0000000000; Name=}
    Material Type                   :
    Factor Value                    : {}
    Accession                       : GSE82255
    Study Identifier                :
    Study Protocol Name             :
    Study Assay Technology Type     :
    Acknowledgments                 :
    Study Assay Technology Platform : GPL13112 GPL16417
    Study Person                    : @{Last Name=Lee; Middle Initials=T; First Name=Jeannie}
    Study Protocol Type             :
    Space Program                   :
    Study Title                     : Destabilization of B2 RNA by EZH2 activates the stress response
    Study Factor Type               : {}
    Study Public Release Date       : 1482148800
    Parameter Value                 : {}
    thumbnail                       :
    Study Factor Name               :
    Study Assay Measurement Type    :
    Project Type                    : Genome binding/occupancy profiling by high throughput sequencing Other Non-coding RNA profiling by high
                                    throughput sequencing Expression profiling by high throughput sequencing
    Project Identifier              :
    Data Source Accession           : GSE82255
    Data Source Type                : nih_geo_gse
    Project Title                   :
    Study Funding Agency            :
    Study Protocol Description      :
    Experiment Platform             :
    Characteristics                 : {}
    Study Grant Number              :
    Study Publication Author List   : Athanasios,,Zovoilis Jeannie,T,Lee Hsueh-Ping,,Chu
    Project Link                    :
    Study Publication Title         :
    Managing NASA Center            :
    Study Description               : More than 98% of the mammalian genome is noncoding and interspersed transposable elements account for
                                    ~50% of noncoding space. Here, we demonstrate that a specific interaction between the Polycomb protein,
                                    EZH2, and RNA made from B2 SINE retrotransposons controls stress-responsive genes in mouse cells. In the
                                    heat shock model, B2 RNA binds stress genes and suppresses their transcription. Upon stress, EZH2 is
                                    recruited and triggers cleavage of B2 RNA. B2 degradation in turn upregulates stress genes. Evidence
                                    indicates that B2 RNA operates as "speed bumps" against advancement of RNA Polymerase II and temperature
                                    stress releases the brakes on transcriptional elongation. These data attribute a new function to EZH2
                                    that is independent of its histone methyltransferase activity and reconcile how EZH2 can be associated
                                    with both gene repression and activation. Our study reveals that EZH2 and B2 together control activation
                                    of a large network of genes involved in thermal stress.
    organism                        : {Mus musculus}

    .LINK

    https://api.nasa.gov/index.html

#>
function Get-NASAGeneLabData {

    [CmdletBinding()]
    param(
        [Parameter()]
        [System.String]
        $token = $env:NasaKey,
        [Parameter()]
        [System.String]
        $url = "https://genelab-data.ndc.nasa.gov/genelab/data/search?term=space&from=0&type=cgene,nih_geo_gse&ffield=links&fvalue=GPL16417&ffield=Data Source Accession&fvalue=GSE82255&api_key=$token"
    )
    begin {

    }
    process {
        $nasa_data = Invoke-RestMethod -Uri $url
        Write-Output "`n"
        Write-Output "This is a static link to a study of mice RNA in space studying the stress response. If you would like to examine other studies, please take a look here: https://api.nasa.gov/api.html#genelab"
        Write-Output "`n"
        $nasa_data.hits.hits._source
    }
}
