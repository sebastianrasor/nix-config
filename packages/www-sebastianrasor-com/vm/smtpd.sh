#!/bin/sh
set -u

CR=$(printf '\r')

reply() {
  printf '%s\r\n' "$1"
}

tmp="/tmp/smtp.$$"
held_lock=0

cleanup() {
  rm -f "$tmp"
  if [ "$held_lock" -eq 1 ]; then
    rmdir /tmp/smtp.lock 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

mail_from=""
has_mail=0
has_rcpt=0

reply "220 www.sebastianrasor.com ESMTP"

while IFS= read -r line; do
  line="${line%"$CR"}"

  case "$line" in
    [Ee][Hh][Ll][Oo]\ *|[Ee][Hh][Ll][Oo]|[Hh][Ee][Ll][Oo]\ *|[Hh][Ee][Ll][Oo])
      mail_from=""
      has_mail=0
      has_rcpt=0
      reply "250 www.sebastianrasor.com"
      ;;
    [Mm][Aa][Ii][Ll]\ [Ff][Rr][Oo][Mm]:*)
      rest="${line#*:}"
      while [ "${rest# }" != "$rest" ]; do
        rest="${rest# }"
      done
      rest="${rest#<}"
      mail_from=$(printf '%s' "${rest%>*}" | tr -d '\t\r\n')
      has_mail=1
      has_rcpt=0
      reply "250 2.1.0 Ok"
      ;;
    [Rr][Cc][Pp][Tt]\ [Tt][Oo]:*)
      if [ "$has_mail" -eq 0 ]; then
        reply "503 5.5.1 Error: need MAIL command"
      else
        has_rcpt=1
        reply "250 2.1.5 Ok"
      fi
      ;;
    [Dd][Aa][Tt][Aa])
      if [ "$has_rcpt" -eq 0 ]; then
        reply "503 5.5.1 Error: need RCPT command"
        continue
      fi
      reply "354 End data with <CR><LF>.<CR><LF>"
      : > "$tmp"
      while IFS= read -r dline; do
        dline="${dline%"$CR"}"
        [ "$dline" = "." ] && break
        case "$dline" in
          ..*) dline="${dline#.}" ;;
        esac
        printf '%s\n' "$dline" >> "$tmp"
      done

      b64=$(base64 < "$tmp" | tr -d '\r\n')
      rm -f "$tmp"

      while ! mkdir /tmp/smtp.lock 2>/dev/null; do
        sleep 1
      done
      held_lock=1

      exec 3<>/dev/ttyS0
      stty raw -echo <&3
      printf '\002SMTP\t%s\t%s\n' "$mail_from" "$b64" >&3
      IFS= read -r smtp_resp <&3
      exec 3>&-

      rmdir /tmp/smtp.lock 2>/dev/null || true
      held_lock=0

      smtp_resp="${smtp_resp%"$CR"}"
      case "$smtp_resp" in
        2*) ;;
        *) printf 'smtpd: %s\n' "$smtp_resp" >&2 ;;
      esac
      reply "$smtp_resp"
      mail_from=""
      has_mail=0
      has_rcpt=0
      ;;
    [Rr][Ss][Ee][Tt]|[Rr][Ss][Ee][Tt]\ *)
      mail_from=""
      has_mail=0
      has_rcpt=0
      reply "250 2.0.0 Ok"
      ;;
    [Nn][Oo][Oo][Pp]|[Nn][Oo][Oo][Pp]\ *)
      reply "250 2.0.0 Ok"
      ;;
    [Qq][Uu][Ii][Tt]|[Qq][Uu][Ii][Tt]\ *)
      reply "221 2.0.0 Bye"
      exit 0
      ;;
    *)
      reply "502 5.5.2 Error: command not recognized"
      ;;
  esac
done
