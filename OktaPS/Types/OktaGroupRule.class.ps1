enum GroupRuleStatus {
    ACTIVE
    INACTIVE
    INVALID
}


class GroupRuleAssignment {
    [string[]] $groupIds

    GroupRuleAssignment([object]$hashtable) {
        $this.groupIds = $hashtable.groupIds
    }
}

class GroupRuleAction {
    [GroupRuleAssignment] $assignUserToGroups

    GroupRuleAction([object]$hashtable) {
        $this.assignUserToGroups = $hashtable.assignUserToGroups
    }
}

class GroupRuleExpression {
    [string] $type
    [string] $value

    GroupRuleExpression([object]$hashtable) {
        $this.type = $hashtable.type
        $this.value = $hashtable.value
    }
}

class GroupRuleGroupCondition {
    [string[]] $exclude

    GroupRuleGroupCondition([object]$hashtable) {
        $this.exclude = $hashtable.exclude
    }
}

class GroupRuleUserCondition {
    [string[]] $exclude

    GroupRuleUserCondition([object]$hashtable) {
        $this.exclude = $hashtable.exclude
    }
}

class GroupRulePeopleCondition {
    [GroupRuleGroupCondition] $groups
    [GroupRuleUserCondition] $users

    GroupRulePeopleCondition([object]$hashtable) {
        $this.groups = $hashtable.groups
        $this.users = $hashtable.users
    }
}

class GroupRuleConditions {
    [GroupRuleExpression] $expression
    [GroupRulePeopleCondition] $people

    GroupRuleConditions([object]$hashtable) {
        $this.expression = $hashtable.expression
        $this.people = $hashtable.people
    }
}

class OktaGroupRule {
    [GroupRuleAction] $actions
    [GroupRuleConditions] $conditions
    [DateTime] $created
    [string] $id
    [DateTime] $lastUpdated
    [string] $name
    [GroupRuleStatus] $status
    [string] $type

    OktaGroupRule([string]$identity) {
        If($identity -like "0pr*") {
            $that = Get-OktaGroupRule -Id $identity -ErrorAction Stop
        } else {
            $that = Get-OktaGroupRule -Search $identity -ErrorAction Stop
        }

        foreach($key in $that.psobject.properties.name) {
            try {
                $this.$key = $that.$key
            } catch {
                $this | Add-Member -NotePropertyName $key -NotePropertyValue $that.$key
            }
        }
    }

    OktaGroupRule([object]$hashtable) {
        $this.actions = $hashtable.actions
        $this.conditions = $hashtable.conditions
        $this.created = $hashtable.created
        $this.id = $hashtable.id
        $this.lastUpdated = $hashtable.lastUpdated
        $this.name = $hashtable.name
        $this.status = $hashtable.status
        $this.type = $hashtable.type
    }
}
