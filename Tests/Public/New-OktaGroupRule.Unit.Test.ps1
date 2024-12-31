BeforeAll {
    Mock Invoke-WebRequest {}
}

Describe "New-OktaGroupRule" {
    Context "" {
        It "" {
            $expectedBody = @{
                type = "group_rule"
                name = "Engineering group rule"
                conditions = @{
                    people = @{
                        users = @{
                            exclude = @(
                                "00u22w79JPMEeeuLr0g4"
                            )
                        }
                        groups = @{
                            exclude = @()
                        }
                    }
                    expression = @{
                        value = "user.role==`"Engineer`""
                        type = "urn:okta:expression:1.0"
                    }
                }
                actions = @{
                    assignUserToGroups = @{
                        groupIds = @(
                            "00gjitX9HqABSoqTB0g3"
                        )
                    }
                }
            }

            Should -BeExactly $expectedBody
        }
    }
}
