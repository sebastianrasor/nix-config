gpg --quiet --import "$1"
for id in $(gpg --show-key --with-colons "$1" | grep '^pub:' | cut -d: -f5); do
	{
		echo trust
		echo 5
		echo y
		echo quit
	} | gpg --no-tty --command-fd 0 --edit-key "$id"
done
shopt -s nullglob
for key in "$GNUPGHOME"/private-keys-v1.d/*.key; do
	if grep -q 'shadowed-private-key' "$key" && ! grep -q '^Prompt:' "$key"; then
		echo 'Prompt: no' >>"$key"
	fi
done
