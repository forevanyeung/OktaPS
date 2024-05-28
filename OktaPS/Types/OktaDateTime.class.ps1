class OktaDateTime {
    [DateTime] $Value

    OktaDateTime([DateTime] $value) {
        $this.Value = $value
    }

    static [OktaDateTime] Parse([string] $value) {
        return [OktaDateTime]::new([DateTime]::Parse($value))
    }

    [string] ToString() {
        return $this.Value.ToString()
    }
}
