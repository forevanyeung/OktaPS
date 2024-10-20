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
    
    OktaGroup([string]$name) {
        $that = Get-OktaGroup -Name $name -ErrorAction Stop

        # $this._embedded = $that._embedded
        # $this._links = $that._links
        $this.created = $that.created
        $this.id = $that.id
        $this.lastMembershipUpdated = $that.lastMembershipUpdated
        $this.lastUpdated = $that.lastUpdated
        $this.objectClass = $that.objectClass
        $this.profile = $that.profile
        $this.type = $that.type
        $this.source = $that.source
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
