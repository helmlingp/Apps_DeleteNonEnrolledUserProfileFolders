<#	
  .Synopsis
    Script to delete user profile folders not accessed for more than 1 month
  .NOTES
    Created:   	    January, 2021
    Created by:	    Phil Helmling, @philhelmling
    Organization:   VMware, Inc.
    Filename:       Delete_NonEnrolled_UserProfileFolders.ps1
    GitHub:         https://github.com/helmlingp/Apps_DeleteNonEnrolledUserProfileFolders 
  .DESCRIPTION
    Script to delete user profile folders not accessed for more than 1 month
    Does NOT delete user profile folder of enrolled user as this breaks enrollment
    
  .EXAMPLE
    powershell.exe -ep bypass -file .\Delete_NonEnrolled_UserProfileFolders.ps1
#>
#Variables
$months = -1

#Getting UPN from MDM Enrollment
$enrolid = (Get-ItemProperty -Path "HKLM:SOFTWARE\Microsoft\Provisioning\OMADM\Accounts\*" -ErrorAction SilentlyContinue).PSChildname
#loops through in case of more than one GUID on the system
foreach ($row in $enrolid) {
    $PATH2 = "HKLM:\SOFTWARE\Microsoft\Enrollments\$row"
    $upn = (Get-ItemProperty -Path $PATH2 -ErrorAction SilentlyContinue).UPN
    $SID = (Get-ItemProperty -Path $PATH2 -ErrorAction SilentlyContinue).SID
}
 
#Getting SID/SAMName from UPN
$AdObj = New-Object System.Security.Principal.NTAccount($upn)
$strSID = $AdObj.Translate([System.Security.Principal.SecurityIdentifier])
$strSID.Value
$profiledonotdelete = gwmi win32_userprofile | where-object sid -eq $strSID.Value
$profiledonotdelete.LocalPath

#list profiles and do not delete the one associated with enrollment
#should also only keep latest 10 profiles
$profiles = Get-ChildItem -Path "C:\Users"
foreach ($p in $profiles){ 
    if($p.FullName -eq $profiledonotdelete -or $p.Name -eq "Public") {
        # Do nothing to the C:\Users\Public folder and the enrolled user profile folder
        #write-host "$p enrollment or public profile that won't be deleted"
    } else {
        $lastaccess = $p.LastAccessTime
        $lastmonth = (Get-Date).addmonths($months)
        if($lastaccess -le $lastmonth){
            #write-host "$p profile that can be deleted"
            Remove-Item -Path $p -Recurse -Force
        } else {
            #write-host "$p profile that won't be deleted"
        }
    }
}