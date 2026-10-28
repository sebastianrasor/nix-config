output="${1:-eDP-1}"
monitor-sensor --accel | while IFS= read -r line; do
	case "$line" in
	*"Accelerometer orientation changed: normal") wlr-randr --output "$output" --transform normal ;;
	*"Accelerometer orientation changed: left-up") wlr-randr --output "$output" --transform 90 ;;
	*"Accelerometer orientation changed: bottom-up") wlr-randr --output "$output" --transform 180 ;;
	*"Accelerometer orientation changed: right-up") wlr-randr --output "$output" --transform 270 ;;
	esac
done
