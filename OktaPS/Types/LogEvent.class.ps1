class Actor {
    [ValidateNotNullOrEmpty()]
    [string]$id
    [string]$type
    [string]$alternateId
    [string]$displayName
    [hashtable]$detailEntry

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

class UserAgent {
    [string]$browser
    [string]$os
    [string]$rawUserAgent

    UserAgent([object]$hashtable) {
        $this.browser = $hashtable.browser
        $this.os = $hashtable.os
        $this.rawUserAgent = $hashtable.rawUserAgent
    }
}

class Request {
    [IpAddress[]]$ipChain

    Request([object]$hashtable) {
        $this.ipChain = $hashtable.ipChain
    }
}

class Geolocation {
    [string]$lat
    [string]$lon

    Geolocation([object]$hashtable) {
        $this.lat = $hashtable.lat
        $this.lon = $hashtable.lon
    }
}

class GeographicalContext {
    [Geolocation]$geolocation
    [string]$city
    [string]$state
    [string]$country
    [string]$postalCode

    GeographicalContext([object]$hashtable) {
        $this.geolocation = $hashtable.geolocation
        $this.city = $hashtable.city
        $this.state = $hashtable.state
        $this.country = $hashtable.country
        $this.postalCode = $hashtable.postalCode
    }
}

class Client {
    [string]$id
    [UserAgent]$userAgent
    [GeographicalContext]$geographicalContext
    [string]$zone
    [string]$ipAddress
    [string]$device

    Client([object]$hashtable) {
        $this.id = $hashtable.id
        $this.userAgent = $hashtable.userAgent
        $this.geographicalContext = $hashtable.geographicalContext
        $this.zone = $hashtable.zone
        $this.ipAddress = $hashtable.ipAddress
        $this.device = $hashtable.device
    }
}

class Outcome {
    [string]$result
    [string]$reason

    Outcome([object]$hashtable) {
        $this.result = $hashtable.result
        $this.reason = $hashtable.reason
    }

    [string] ToString() {
        return $this.result
    }
}

class Transaction {
    [string]$id
    [string]$type
    [hashtable]$detail

    Transaction([object]$hashtable) {
        $this.id = $hashtable.id
        $this.type = $hashtable.type
        $this.detail = $hashtable.detail
    }
}

class DebugContext {
    [hashtable]$debugData

    DebugContext([object]$hashtable) {
        $this.debugData = $hashtable.debugData
    }
}

class Issuer {
    [string]$id
    [string]$type

    Issuer([object]$hashtable) {
        $this.id = $hashtable.id
        $this.type = $hashtable.type
    }
}

class AuthenticationContext {
    [string]$authenticationProvider
    [int]$authenticationStep
    [string]$credentialProvider
    [string]$credentialType
    [Issuer]$issuer
    [string]$externalSessionId
    [string]$interface

    AuthenticationContext([object]$hashtable) {
        $this.authenticationProvider = $hashtable.authenticationProvider
        $this.authenticationStep = $hashtable.authenticationStep
        $this.credentialProvider = $hashtable.credentialProvider
        $this.credentialType = $hashtable.credentialType
        $this.issuer = $hashtable.issuer
        $this.externalSessionId = $hashtable.externalSessionId
        $this.interface = $hashtable.interface
    }
}

class SecurityContext {
    [int]$asNumber
    [string]$asOrg
    [string]$isp
    [string]$domain
    [bool]$isProxy

    SecurityContext([object]$hashtable) {
        $this.asNumber = $hashtable.asNumber
        $this.asOrg = $hashtable.asOrg
        $this.isp = $hashtable.isp
        $this.domain = $hashtable.domain
        $this.isProxy = $hashtable.isProxy
    }
}

class IpAddress {
    [string]$ip
    [GeographicalContext]$geographicalContext
    [string]$version
    [string]$source

    IpAddress([object]$hashtable) {
        $this.ip = $hashtable.ip
        $this.geographicalContext = $hashtable.geographicalContext
        $this.version = $hashtable.version
        $this.source = $hashtable.source
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
    [Client]$client
    [Request]$request
    [Outcome]$outcome
    [Target[]]$target
    [Transaction]$transaction
    [DebugContext]$debugContext
    [AuthenticationContext]$authenticationContext
    [SecurityContext]$securityContext

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
        $this.client = $hashtable.client
        $this.request = $hashtable.request
        $this.outcome = $hashtable.outcome
        $this.transaction = $hashtable.transaction
        $this.debugContext = $hashtable.debugContext
        $this.authenticationContext = $hashtable.authenticationContext
        $this.securityContext = $hashtable.securityContext
    }
}
