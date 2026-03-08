Function Start-OktaSessionRefreshTimer {
    [CmdletBinding()]
    param (
        [int]$CheckIntervalSeconds = 3,
        [int]$RefreshThresholdSeconds = 880
    )

    Stop-OktaSessionRefreshTimer

    $timer = [System.Timers.Timer]::new($CheckIntervalSeconds * 1000)
    $timer.AutoReset = $true

    # PSEventJob runs in an isolated runspace - $Script:OktaAuth is passed via MessageData.State
    # so the timer can read/write auth state (SSOExpirationUTC, Domain, SSO) across the runspace boundary.
    $action = {
        $verbosePref = $Event.MessageData.VerbosePreference
        $warningPref = $Event.MessageData.WarningPreference
        Function Write-Verbose { 
            param([string]$Message)
            if ($verbosePref -ne 'SilentlyContinue') { $Host.UI.WriteVerboseLine("[OktaIDXRefreshTimer] $Message") } 
        }
        Function Write-Warning { 
            param([string]$Message)
            if ($warningPref -ne 'SilentlyContinue') { $Host.UI.WriteWarningLine("[OktaIDXRefreshTimer] $Message") } 
        }

        try {
            $state     = $Event.MessageData.State
            $threshold = $Event.MessageData.Threshold

            if (-not $state.SSOExpirationUTC) {
                Write-Verbose "No session expiration found"
                return
            }

            $timeLeft = ($state.SSOExpirationUTC - (Get-Date).ToUniversalTime()).TotalSeconds
            Write-Verbose "${timeLeft}s remaining (threshold: ${threshold}s)"

            if ($timeLeft -gt $threshold) { return }

            Write-Verbose "Refreshing session..."
            $session = Invoke-RestMethod -Method POST -Uri "$($state.AdminDomain)/api/v1/sessions/me/lifecycle/refresh" -WebSession $state.SSO -ContentType "application/json" -ErrorAction Stop

            if ($session.status -eq "ACTIVE") {
                $state.SSOExpirationUTC = [datetime]$session.expiresAt
                Write-Verbose "Session refreshed, new expiry: $($state.SSOExpirationUTC)"
            } else {
                $Sender.Stop()
                Unregister-Event -SourceIdentifier "OktaIDXRefreshTimer" -ErrorAction SilentlyContinue
                Write-Warning "Session refresh failed. Re-run Connect-Okta to re-authenticate."
            }
        } catch {
            $Sender.Stop()
            Unregister-Event -SourceIdentifier "OktaIDXRefreshTimer" -ErrorAction SilentlyContinue
            Write-Warning "Session refresh error: $_. Re-run Connect-Okta to re-authenticate."
        }
    }

    $Script:OktaAuth.RefreshTimer = $timer
    $messageData = @{
        State             = $Script:OktaAuth
        Threshold         = $RefreshThresholdSeconds
        VerbosePreference = $VerbosePreference
        WarningPreference = $WarningPreference
    }
    Register-ObjectEvent -InputObject $timer -EventName "Elapsed" -SourceIdentifier "OktaIDXRefreshTimer" -Action $action -MessageData $messageData | Out-Null
    $timer.Start()

    Write-Verbose "Session refresh timer started (check every ${CheckIntervalSeconds}s, refresh threshold ${RefreshThresholdSeconds}s)"
}
