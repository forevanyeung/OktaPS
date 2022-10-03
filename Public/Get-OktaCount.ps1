Function Get-OktaCount {
    # unofficial api
    Write-OktaAdminAPIWarning

    $return = [ordered]@{
        "users" = [ordered]@{
            "total" = (Invoke-OktaRequest -Method "GET" -Endpoint "api/internal/people/count?filter=EVERYONE").count
            "active" = (Invoke-OktaRequest -Method "GET" -Endpoint "api/internal/people/count?filter=ACTIVATED").count
            "password_reset" = (Invoke-OktaRequest -Method "GET" -Endpoint "api/internal/people/count?filter=PASSWORD_RESET").count
            "locked_out" = (Invoke-OktaRequest -Method "GET" -Endpoint "api/internal/people/count?filter=LOCKED_OUT").count
            "suspended" = (Invoke-OktaRequest -Method "GET" -Endpoint "api/internal/people/count?filter=SUSPENDED").count
            "deactivated" = (Invoke-OktaRequest -Method "GET" -Endpoint "api/internal/people/count?filter=DEACTIVATED").count
        }
    }

    $return
}