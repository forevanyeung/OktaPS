enum GroupType {
    OKTA_GROUP
    APP_GROUP
    BUILT_IN
}

class OktaGroup {
    [hashtable]          $_embedded
    [hashtable]          $_links
    [DateTime]           $created
    [ValidateNotNullOrEmpty()]
    [string]             $id
    [DateTime]           $lastMembershipUpdated
    [DateTime]           $lastUpdated
    [string[]]           $objectClass
    [PSCustomObject]     $profile
    [GroupType]          $type
    [string[]]           $source
    
    OktaUser([string]$name) {
        Get-OktaGroup -Name $name -ErrorAction Stop
    }

    OktaGroup([object]$hashtable) {
        # $this._embedded             = $hashtable._embedded
        # $this._links                = $hashtable._links
        $this.created               = $hashtable.created ?? [DateTime]::MinValue
        $this.id                    = $hashtable.id
        $this.lastMembershipUpdated = $hashtable.lastMembershipUpdated ?? [DateTime]::MinValue
        $this.lastUpdated           = $hashtable.lastUpdated ?? [DateTime]::MinValue
        $this.objectClass           = $hashtable.objectClass
        $this.profile               = $hashtable.profile
        $this.type                  = $hashtable.type ?? "OKTA_GROUP"
        $this.source                = $hashtable.source.id
    }
}
