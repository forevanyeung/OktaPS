Class OktaUser {
    [ValidateNotNullorEmpty()]
    [string] $id
    [string] $status
    [string] $firstName
    [string] $lastName
    [string] $login
    [string] $enabled
    [datetime] $created
    [datetime] $activated
    [datetime] $statusChanged
    [datetime] $lastLogin
    [datetime] $lastUpdated
    [datetime] $passwordChanged 
    [string] $type
    # [OktaGroup] $_groups
    [string] $_links
    [hashtable] $_profile

    OktaUser([string]$identity) {
        $that = Get-OktaUser -Identity $identity -ErrorAction Stop
        foreach($key in $that.psobject.properties.name) {
            try {
                $this.$key = $that.$key
            } catch {
                $this | Add-Member -NotePropertyName $key -NotePropertyValue $that.$key
            }
        }
    }

    OktaUser(
        [string]$id,
        [string]$status,
        [string]$firstName,
        [string]$lastName,
        [string]$login,
        [datetime]$created,
        [datetime]$activated,
        [datetime]$statusChanged,
        [datetime]$lastLogin,
        [datetime]$lastUpdated,
        [datetime]$passwdChanged
        # [string]$type
    ){
        $this.id            = $id
        $this.status        = $status 
        $this.firstName     = $firstName
        $this.lastName      = $lastName
        $this.login         = $login
        $this.enabled       = $status -in @("STAGED", "PROVISIONED", "ACTIVE", "RECOVERY", "PASSWORD_EXPIRED", "LOCKED_OUT", "SUSPENDED") ? $True : $False
        $this.created       = $created
        $this.activated     = $activated
        $this.statusChanged = $statusChanged
        $this.lastLogin     = $lastLogin
        $this.lastUpdated   = $lastUpdated
        $this.passwordChanged   = $passwdChanged
        # $this.type          = $type
    }
}
