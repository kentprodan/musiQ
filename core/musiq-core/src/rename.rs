//! File rename/move on disk from a tag-based pattern (Mp3Tag's other core
//! feature, alongside tag writing) — e.g. `{artist}/{album}/{title}` moves a
//! file into an artist/album folder structure named after its own tags.

/// Substitutes `{title}`/`{artist}`/`{album}` in `pattern` with sanitized
/// values. The pattern's own `/`/`\` characters are left alone (they're the
/// path separators the caller intended); only the substituted values are
/// stripped of filesystem-illegal characters.
pub fn apply_pattern(pattern: &str, title: &str, artist: &str, album: &str) -> String {
    pattern
        .replace("{title}", &sanitize_component(title))
        .replace("{artist}", &sanitize_component(artist))
        .replace("{album}", &sanitize_component(album))
}

/// Strips characters that are illegal in a Windows (and, incidentally, most
/// Unix-friendly) filename, since tag values are free text and routinely
/// contain things like `AC/DC` or `Artist: Live`.
fn sanitize_component(value: &str) -> String {
    value
        .chars()
        .map(|c| match c {
            '\\' | '/' | ':' | '*' | '?' | '"' | '<' | '>' | '|' => '_',
            other => other,
        })
        .collect::<String>()
        .trim()
        .to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn substitutes_placeholders_and_keeps_pattern_separators() {
        let result = apply_pattern("{artist}/{album}/{title}", "Song", "AC/DC", "Back in Black");
        assert_eq!(result, "AC_DC/Back in Black/Song");
    }

    #[test]
    fn sanitizes_illegal_windows_filename_characters() {
        let result = apply_pattern("{title}", "Artist: Live?", "", "");
        assert_eq!(result, "Artist_ Live_");
    }
}
