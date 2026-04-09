[
	(.installer | map(select(.stable) .version ) | max) as $installer
	| (.loader | map(select(.stable) .version ) | max) as $loader
	| .game[]
	| ("https://meta.fabricmc.net/v2/versions/loader/\(.version)/\($loader)/\($installer)/server/jar") as $url 
	| select(.stable) 
	| {
		(.version): {
			url: $url,
			sha256: "$(nix-prefetch-url --type sha256 '\($url)')"
		}
	}
]
| add

