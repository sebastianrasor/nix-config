monitor-sensor --accel | while IFS= read -r line; do
	case "$line" in
	*"Accelerometer orientation changed: normal") wlr-randr --output eDP-1 --transform normal ;;
	*"Accelerometer orientation changed: left-up") wlr-randr --output eDP-1 --transform 90 ;;
	*"Accelerometer orientation changed: bottom-up") wlr-randr --output eDP-1 --transform 180 ;;
	*"Accelerometer orientation changed: right-up") wlr-randr --output eDP-1 --transform 270 ;;
	esac
done
