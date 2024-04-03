class GroupRuleStatus {
    [ValidateSet("ACTIVE", "INACTIVE", "INVALID")]
    [string]$status

    GroupRuleStatus([string]$status) {
        $this.status = $status
    }

    [string] ToString() {
        return $this.status
    }
}

class GroupRuleExpression {
    [string]$type
    [string]$value
}

class GroupRuleGroupCondition {
    [string[]]$exclude
    [string[]]$include
}

class GroupRuleUserCondition {
    [string[]]$exclude
    [string[]]$include
}

class GroupRulePeopleCondition {
    [GroupRuleGroupCondition]$groups
    [GroupRuleUserCondition]$users
}

class GroupRuleConditions {
    [GroupRuleExpression]$expression
    [GroupRulePeopleCondition]$people

    [string] ToString() {
        return $this.expression.value
    }
}

class GroupRuleGroupAssignment {
    [string[]]$groupIds

    [string] ToString() {
        return $this.groupIds -join ", "
    }
}

class GroupRuleAction {
    [GroupRuleGroupAssignment]$assignUserToGroups

    [string] ToString() {
        return $this.assignUserToGroups.groupIds -join ", "
    }
}

Class OktaGroupRule {
    [ValidateNotNullOrEmpty()]
    [string]$id
    [string]$type
    [string]$name
    [datetime]$created
    [datetime]$lastUpdated
    [GroupRuleStatus]$status
    [GroupRuleConditions]$conditions
    [GroupRuleAction]$actions

    OktaGroupRule([object]$hashtable) {
        $this.id = $hashtable.id
        $this.type = $hashtable.type
        $this.name = $hashtable.name
        $this.created = [datetime]::MinValue
        $this.lastUpdated = $hashtable.lastUpdated ?? [datetime]::MinValue
        $this.status = [GroupRuleStatus]$hashtable.status
        $this.conditions = [GroupRuleConditions]$hashtable.conditions
        $this.actions = [GroupRuleAction]$hashtable.actions
    } 
}
