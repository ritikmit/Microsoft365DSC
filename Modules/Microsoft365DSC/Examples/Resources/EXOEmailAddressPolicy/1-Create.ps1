<#
This example is used to test new resources and showcase the usage of new resources being worked on.
It is not meant to use as a production baseline.
#>

Configuration Example
{
    param(
        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )
    Import-DscResource -ModuleName Microsoft365DSC

    $Domain = $Credscredential.Username.Split('@')[1]
    node localhost
    {
        EXOEmailAddressPolicy 'ConfigureEmailAddressPolicy'
        {
            Name                              = "Integration Policy"
            EnabledEmailAddressTemplates      = @("SMTP:@$TenantId")
            EnabledPrimarySMTPAddressTemplate = "@$TenantId"
            ManagedByFilter                   = ""
            Priority                          = 1
            Ensure                            = "Present"
            ApplicationId         = $ApplicationId
            TenantId              = $TenantId
            CertificateThumbprint = $CertificateThumbprint
        }
    }
}
