param([string]$event = "stop")
python "$env:USERPROFILE\.claude\hooks\notify.py" $event
