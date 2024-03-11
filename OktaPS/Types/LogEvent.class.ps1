class Actor {
    [ValidateNotNullOrEmpty()]
    [string]$id
    [string]$type
    [string]$alternateId
    [string]$displayName
    [hashtable]$detailEntry

    Actor([string]$id, [string]$type, [string]$alternateId, [string]$displayName, [hashtable]$detailEntry) {
        $this.id = $id
        $this.type = $type
        $this.alternateId = $alternateId
        $this.displayName = $displayName
        $this.detailEntry = $detailEntry
    }

    Actor([object]$hashtable) {
        $this.id = $hashtable.id
        $this.type = $hashtable.type
        $this.alternateId = $hashtable.alternateId
        $this.displayName = $hashtable.displayName
        $this.detailEntry = $hashtable.detailEntry
    }

    [string] ToString() {
        return $this.displayName
    }
}

class Target {
    [ValidateNotNullOrEmpty()]
    [string]$id
    [string]$type
    [string]$alternateId
    [string]$displayName
    [object]$detailEntry

    Target([string]$id, [string]$type, [string]$alternateId, [string]$displayName, [object]$detailEntry) {
        $this.id = $id
        $this.type = $type
        $this.alternateId = $alternateId
        $this.displayName = $displayName
        $this.detailEntry = $detailEntry
    }

    Target([object]$hashtable) {
        $this.id = $hashtable.id
        $this.type = $hashtable.type
        $this.alternateId = $hashtable.alternateId
        $this.displayName = $hashtable.displayName
        $this.detailEntry = $hashtable.detailEntry
    }

    [string] ToString() {
        return $this.displayName
    }
}

class LogEvent {
    [string]$uuid
    [datetime]$published
    [string]$eventType
    [string]$version
    [string]$severity
    [string]$legacyEventType
    [string]$displayMessage
    [Actor]$actor
    [Target[]]$target

    LogEvent([object]$hashtable) {
        $this.uuid = $hashtable.uuid
        $this.published = $hashtable.published
        $this.eventType = $hashtable.eventType
        $this.version = $hashtable.version
        $this.severity = $hashtable.severity
        $this.legacyEventType = $hashtable.legacyEventType
        $this.displayMessage = $hashtable.displayMessage
        $this.actor = $hashtable.actor
        $this.target = $hashtable.target
    }
}
