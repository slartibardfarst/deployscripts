$versionPattern = '[0-9]+(\.([0-9]+|\*)){3}'
$assemblyVersionPattern = "AssemblyVersion\(`"($versionPattern)`"\)"
$assemblyFileVersionPattern = "AssemblyFileVersion\(`"($versionPattern)`"\)"



function Set-VersionStringInAssemblyInfoFile
{
    Param
    (
        [string] $assemblyInfoFilepath = $(throw "$assemblyInfoFilepath must be specified."),
        [string] $newVersionString = $(throw "$assemblyInfoFilepath must be specified.")
    )

    $newAssemblyVersion = 'AssemblyVersion("' + $newVersionString + '")';
    $newFileVersion = 'AssemblyFileVersion("' + $newVersionString + '")';


	$tmpFile = $assemblyInfoFilepath + ".tmp"

	get-content $assemblyInfoFilepath | 
       %{$_ -replace $assemblyVersionPattern, $newAssemblyVersion } |
       %{$_ -replace $assemblyFileVersionPattern, $newFileVersion }  > $tmpFile

	move-item $tmpFile $assemblyInfoFilepath -force
}

 

function Update-VersionFile
{
    Param
    (
        [string] $assemblyInfoFilepath = $(throw "$assemblyInfoFilepath must be specified."),
        [string] $majorMinorPatch = $null,
        [string] $buildNumber = $null
    )
   
    #Write-Host 'Update-VersionFile called for file: ' $assemblyInfoFilepath "majorminonorpatch: " $majorMinorPatch "buildNumber: " $buildNumber
   
    $rawVersionNumberGroup = get-content $assemblyInfoFilepath | select-string -pattern $assemblyVersionPattern | select -first 1 | foreach-object { $_.Matches }
    if(!$rawVersionNumberGroup) { return }   

    $rawVersionNumber = $rawVersionNumberGroup.Groups[1].Value
    if($rawVersionNumber)
    {
        $versionParts = $rawVersionNumber.Split('.')

        if($majorMinorPatch)
        {
           $providedParts = $majorMinorPatch.Split('.')
           $versionParts[0] = $providedParts[0];
           $versionParts[1] = $providedParts[1];
           $versionParts[2] = $providedParts[2];
        }

        if($buildNumber)
        {
           $versionParts[3] = $buildNumber;
        }
   
	    $updatedVersion = "{0}.{1}.{2}.{3}" -f $versionParts[0], $versionParts[1], $versionParts[2], $versionParts[3] 
        Set-VersionStringInAssemblyInfoFile -assemblyInfoFilepath $assemblyInfoFilepath -newVersionString $updatedVersion
        Write-Host 'Updated file: ' $assemblyInfoFilepath 'to contain version string: '$updatedVersion

        return $updatedVersion
    }
}
 
 
function Set-VersionFromSourceAndTeamCity
{
    param
    (
       [string] $majorMinorPatch = $null,
       [string] $buildNumber = $null,
       [string] $assemblyInfoFiles = "AssemblyInfo.cs,SolutionVersionInfo.cs",
       [string] $projectRoot = "."
    )
  
    Write-Host "Set-AssemblyAndFileVersionFromSourceCodeAndTeamCity called"
   
    if($majorMinorPatch)
    {
        $versionParts = $majorMinorPatch.Split('.')
        if($versionParts.length -ne 3) {throw "Error: majorMinorPatch must be specified as x.y.z where x,y,z are integers"}
        Write-Host "Updating Major.Minor.Patch to be: " $majorMinorPatch
    }
    if($buildNumber) {Write-Host "Updating build number to:" $buildNumber}
    if(!$assemblyInfoFiles) {throw "Error: a value for AssemblyInfoFiles is required"}
    if(!$majorMinorPatch -and !$buildNumber) {throw "Error: at least one of -majorMinorPatch or -buildNumber must be specified"}
   
    $updatedVersion = ''
   
    foreach($file in $assemblyInfoFiles.Split(","))
    {
       get-childitem -recurse -filter "*.cs" -path $projectRoot|       
          where-object {$_.Name -eq $file} |        
          foreach-object {$updatedVersion = Update-VersionFile -assemblyInfoFilepath $_.FullName -majorMinorPatch $majorMinorPatch -buildNumber $buildNumber}
    }
   
    Write-Host "Updated all occurrences of"$assemblyInfoFiles "to have version" $updatedVersion
}


Write-Host "In Set-Version.ps1"
