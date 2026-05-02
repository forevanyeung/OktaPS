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

class ChangeDetails {
    [hashtable]$from
    [hashtable]$to

    ChangeDetails([object]$hashtable) {
        $this.from = $hashtable.from
        $this.to = $hashtable.to
    }
}

class Target {
    [ValidateNotNullOrEmpty()]
    [string]$id
    [string]$type
    [string]$alternateId
    [string]$displayName
    [object]$detailEntry
    [ChangeDetails]$changeDetails

    Target([object]$hashtable) {
        $this.id = $hashtable.id
        $this.type = $hashtable.type
        $this.alternateId = $hashtable.alternateId
        $this.displayName = $hashtable.displayName
        $this.detailEntry = $hashtable.detailEntry
        $this.changeDetails = $hashtable.changeDetails
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
    [double]$lat
    [double]$lon

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

class LogDevice {
    [string]$id
    [hashtable]$deviceIntegrator
    [string]$diskEncryptionType
    [bool]$jailbreak
    [bool]$managed
    [string]$name
    [string]$osPlatform
    [string]$osVersion
    [bool]$registered
    [string]$screenLockType
    [bool]$secureHardwarePresent

    LogDevice([object]$hashtable) {
        $this.id = $hashtable.id
        if ($hashtable.device_integrator) {
            $this.deviceIntegrator = $hashtable.device_integrator | ConvertFrom-Json -AsHashtable
        }
        $this.diskEncryptionType = $hashtable.disk_encryption_type
        $this.jailbreak = $hashtable.jailbreak
        $this.managed = $hashtable.managed
        $this.name = $hashtable.name
        $this.osPlatform = $hashtable.os_platform
        $this.osVersion = $hashtable.os_version
        $this.registered = $hashtable.registered
        $this.screenLockType = $hashtable.screen_lock_type
        $this.secureHardwarePresent = $hashtable.secure_hardware_present
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

class BotProtection {
    [string]$level

    BotProtection([object]$hashtable) {
        $this.level = $hashtable.level
    }
}

class IpServiceCategory {
    [bool]$isAnonymous
    [string]$operator
    [string]$type

    IpServiceCategory([object]$hashtable) {
        $this.isAnonymous = $hashtable.isAnonymous
        $this.operator = $hashtable.operator
        $this.type = $hashtable.type
    }
}

class IpDetails {
    [Nullable[int]]$asNumber
    [string]$asOrg
    [string]$domain
    [string]$isp
    [IpServiceCategory[]]$ipServiceCategories

    IpDetails([object]$hashtable) {
        $this.asNumber = $hashtable.asNumber
        $this.asOrg = $hashtable.asOrg
        $this.domain = $hashtable.domain
        $this.isp = $hashtable.isp
        $this.ipServiceCategories = $hashtable.ipServiceCategories
    }
}

class Risk {
    [string]$detectionName
    [string]$issuer
    [string]$level
    [string]$previousLevel
    [string[]]$reasons

    Risk([object]$hashtable) {
        $this.detectionName = $hashtable.detectionName
        $this.issuer = $hashtable.issuer
        $this.level = $hashtable.level
        $this.previousLevel = $hashtable.previousLevel
        $this.reasons = $hashtable.reasons
    }
}

class UserBehavior {
    [string]$id
    [string]$name
    [string]$result

    UserBehavior([object]$hashtable) {
        $this.id = $hashtable.id
        $this.name = $hashtable.name
        $this.result = $hashtable.result
    }
}

class SecurityContext {
    [Nullable[int]]$asNumber
    [string]$asOrg
    [string]$isp
    [string]$domain
    [Nullable[bool]]$isProxy
    [BotProtection]$botProtection
    [IpDetails]$ipDetails
    [Risk]$risk
    [UserBehavior[]]$userBehaviors

    SecurityContext([object]$hashtable) {
        $this.asNumber = $hashtable.asNumber
        $this.asOrg = $hashtable.asOrg
        $this.isp = $hashtable.isp
        $this.domain = $hashtable.domain
        $this.isProxy = $hashtable.isProxy
        $this.botProtection = $hashtable.botProtection
        $this.ipDetails = $hashtable.ipDetails
        $this.risk = $hashtable.risk
        $this.userBehaviors = $hashtable.userBehaviors
    }
}

class IpAddress {
    [string]$ip
    [GeographicalContext]$geographicalContext
    [string]$version
    [string]$source
    [IpDetails]$ipDetails

    IpAddress([object]$hashtable) {
        $this.ip = $hashtable.ip
        $this.geographicalContext = $hashtable.geographicalContext
        $this.version = $hashtable.version
        $this.source = $hashtable.source
        $this.ipDetails = $hashtable.ipDetails
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
    [LogDevice]$device
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
        $this.device = $hashtable.device
        $this.request = $hashtable.request
        $this.outcome = $hashtable.outcome
        $this.transaction = $hashtable.transaction
        $this.debugContext = $hashtable.debugContext
        $this.authenticationContext = $hashtable.authenticationContext
        $this.securityContext = $hashtable.securityContext
    }
}
