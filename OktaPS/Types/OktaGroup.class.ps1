Class OktaGroup {
    [ValidateNotNullorEmpty()]
    [string] $id
    [string] $name
    [string] $description
    [string] $type

    OktaGroup([string]$identity) {
        $that = Get-OktaGroup -Name $identity -ErrorAction Stop
        foreach($key in $that.psobject.properties.name) {
            try {
                $this.$key = $that.$key
            } catch {
                $this | Add-Member -NotePropertyName $key -NotePropertyValue $that.$key
            }
        }
    }

    OktaGroup(
        [string]$id,
        [string]$name,
        [string]$description,
        [string]$type
    ){
        $this.id          = $id
        $this.name        = $name
        $this.description = $description
        $this.type        = $type
    }
}