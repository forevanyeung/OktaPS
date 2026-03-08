Function Start-OktaSessionRefreshTimer {
    [CmdletBinding()]
    param (
        [int]$CheckIntervalSeconds = 30,
        [int]$RefreshThresholdSeconds = 300
    )

    Stop-OktaSessionRefreshTimer

    $timer = [System.Timers.Timer]::new($CheckIntervalSeconds * 1000)
    $timer.AutoReset = $true

    # PSEventJob runs in an isolated runspace - $Script:OktaAuth is passed via MessageData.State
    # so the timer can read/write auth state (SSOExpirationUTC, Domain, SSO) across the runspace boundary.
    $action = {
        $debugPref = $Event.MessageData.DebugPreference
        $warningPref = $Event.MessageData.WarningPreference
        Function Write-ThreadDebug { 
            param([string]$Message)
            if ($debugPref -ne 'SilentlyContinue') { $Host.UI.WriteDebugLine("[OktaIDXRefreshTimer] $Message") } 
        }
        Function Write-ThreadWarning { 
            param([string]$Message)
            if ($warningPref -ne 'SilentlyContinue') { $Host.UI.WriteWarningLine("[OktaIDXRefreshTimer] $Message") } 
        }

        try {
            $state     = $Event.MessageData.State
            $threshold = $Event.MessageData.Threshold

            if (-not $state.SSOExpirationUTC) {
                Write-ThreadDebug "No session expiration found"
                return
            }

            $timeLeft = ($state.SSOExpirationUTC - (Get-Date).ToUniversalTime()).TotalSeconds
            Write-ThreadDebug "${timeLeft}s remaining (threshold: ${threshold}s)"

            if ($timeLeft -gt $threshold) { return }

            Write-ThreadDebug "Refreshing session..."
            $session = Invoke-RestMethod -Method POST -Uri "$($state.AdminDomain)/api/v1/sessions/me/lifecycle/refresh" -WebSession $state.SSO -ContentType "application/json" -TimeoutSec 30 -ErrorAction Stop

            if ($session.status -eq "ACTIVE") {
                $state.SSOExpirationUTC = [datetime]$session.expiresAt
                Write-ThreadDebug "Session refreshed, new expiry: $($state.SSOExpirationUTC)"
            } else {
                $Sender.Stop()
                Unregister-Event -SourceIdentifier "OktaIDXRefreshTimer" -ErrorAction SilentlyContinue
                Write-ThreadWarning "Session refresh failed. Re-run Connect-Okta to re-authenticate."
            }
        } catch {
            $Sender.Stop()
            Unregister-Event -SourceIdentifier "OktaIDXRefreshTimer" -ErrorAction SilentlyContinue
            Write-ThreadWarning "Session refresh error: $_. Re-run Connect-Okta to re-authenticate."
        }
    }

    $Script:OktaAuth.RefreshTimer = $timer
    $messageData = @{
        State             = $Script:OktaAuth
        Threshold         = $RefreshThresholdSeconds
        DebugPreference = $DebugPreference
        WarningPreference = $WarningPreference
    }
    Register-ObjectEvent -InputObject $timer -EventName "Elapsed" -SourceIdentifier "OktaIDXRefreshTimer" -Action $action -MessageData $messageData | Out-Null
    $timer.Start()

    Write-Verbose "Session refresh timer started (check every ${CheckIntervalSeconds}s, refresh threshold ${RefreshThresholdSeconds}s)"
}
