use sure_desktop_lib::localization::{resolve_locale, strings, Locale};

#[test]
fn resolves_vietnamese_variants_and_falls_back_to_english() {
    for locale in ["vi", "vi-VN", "vi_VN", "VI-vn"] {
        assert_eq!(resolve_locale(Some(locale)), Locale::Vi);
    }
    for locale in ["en", "en-US", "fr-FR", "", "vietnamese"] {
        assert_eq!(resolve_locale(Some(locale)), Locale::En);
    }
    assert_eq!(resolve_locale(None), Locale::En);
}

#[test]
fn native_menu_and_window_titles_use_the_selected_language() {
    let vi = strings(resolve_locale(Some("vi-VN")));
    assert_eq!(vi.menu.preferences, "Tùy chọn…");
    assert_eq!(vi.menu.switch_server, "Chuyển máy chủ…");
    assert_eq!(vi.menu.file, "Tệp");
    assert_eq!(vi.menu.edit, "Chỉnh sửa");
    assert_eq!(vi.menu.quit, "Thoát Sure");
    assert_eq!(vi.preferences.title, "Tùy chọn");
    assert_eq!(
        strings(resolve_locale(Some("ja"))).menu.preferences,
        "Preferences…"
    );
}
