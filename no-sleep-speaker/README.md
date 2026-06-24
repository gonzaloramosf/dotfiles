: > /tmp/no-sleep-speaker.err.log
: > /tmp/no-sleep-speaker.out.log

launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.no-sleep-speaker.plist 2>/dev/null
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.no-sleep-speaker.plist
launchctl enable gui/$(id -u)/com.no-sleep-speaker
launchctl kickstart -k gui/$(id -u)/com.no-sleep-speaker

cat /tmp/no-sleep-speaker.err.log
launchctl print gui/$(id -u)/com.no-sleep-speaker | grep -E "state|runs|run interval|program"
