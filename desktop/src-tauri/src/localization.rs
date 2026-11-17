use serde::Deserialize;
use std::sync::OnceLock;

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub enum Locale {
    #[default]
    En,
    Vi,
}

impl Locale {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::En => "en",
            Self::Vi => "vi",
        }
    }
}

pub fn resolve_locale(locale: Option<&str>) -> Locale {
    match locale.and_then(|value| value.trim().split(['-', '_']).next()) {
        Some(language) if language.eq_ignore_ascii_case("vi") => Locale::Vi,
        _ => Locale::En,
    }
}

// Read the user's preferred UI language, not their region, currency or server
// account preference. Local webviews receive this same locale through IPC.
#[cfg(target_os = "macos")]
pub fn system_locale() -> Option<String> {
    objc2_foundation::NSLocale::preferredLanguages()
        .firstObject()
        .map(|language| language.to_string())
}

#[cfg(not(target_os = "macos"))]
pub fn system_locale() -> Option<String> {
    ["LC_ALL", "LC_MESSAGES", "LANG"]
        .iter()
        .find_map(|name| std::env::var(name).ok().filter(|value| !value.is_empty()))
}

#[derive(Deserialize)]
pub struct Strings {
    pub preferences: Preferences,
    pub menu: Menu,
    pub notifications: Notifications,
}

#[derive(Deserialize)]
pub struct Preferences {
    pub title: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Menu {
    pub about: String,
    pub preferences: String,
    pub switch_server: String,
    pub hide: String,
    pub hide_others: String,
    pub quit: String,
    pub file: String,
    pub close_window: String,
    pub edit: String,
    pub undo: String,
    pub redo: String,
    pub cut: String,
    pub copy: String,
    pub paste: String,
    pub select_all: String,
    pub reload: String,
    pub view: String,
    pub window: String,
    pub minimize: String,
    pub maximize: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Notifications {
    pub download_complete: String,
    pub download_failed: String,
}

pub fn strings(locale: Locale) -> &'static Strings {
    static EN: OnceLock<Strings> = OnceLock::new();
    static VI: OnceLock<Strings> = OnceLock::new();
    let (cache, json) = match locale {
        Locale::En => (&EN, include_str!("../../src/locales/en.json")),
        Locale::Vi => (&VI, include_str!("../../src/locales/vi.json")),
    };
    cache.get_or_init(|| serde_json::from_str(json).expect("valid bundled desktop translations"))
}
