use tauri::menu::{AboutMetadata, Menu, MenuItem, PredefinedMenuItem, Submenu};
use tauri::Manager;

pub fn build(
    app: &tauri::AppHandle,
    locale: crate::localization::Locale,
) -> tauri::Result<Menu<tauri::Wry>> {
    let pkg = app.package_info().clone();
    let text = &crate::localization::strings(locale).menu;

    let prefs = MenuItem::with_id(app, "preferences", &text.preferences, true, Some("Cmd+,"))?;
    let switch = MenuItem::with_id(
        app,
        "switch_server",
        &text.switch_server,
        true,
        Some("Cmd+Shift+O"),
    )?;
    let app_menu = Submenu::with_items(
        app,
        &pkg.name,
        true,
        &[
            &PredefinedMenuItem::about(app, Some(&text.about), Some(AboutMetadata::default()))?,
            &PredefinedMenuItem::separator(app)?,
            &prefs,
            &switch,
            &PredefinedMenuItem::separator(app)?,
            &PredefinedMenuItem::hide(app, Some(&text.hide))?,
            &PredefinedMenuItem::hide_others(app, Some(&text.hide_others))?,
            &PredefinedMenuItem::separator(app)?,
            &PredefinedMenuItem::quit(app, Some(&text.quit))?,
        ],
    )?;

    let file_menu = Submenu::with_items(
        app,
        &text.file,
        true,
        &[&PredefinedMenuItem::close_window(
            app,
            Some(&text.close_window),
        )?],
    )?;

    let edit_menu = Submenu::with_items(
        app,
        &text.edit,
        true,
        &[
            &PredefinedMenuItem::undo(app, Some(&text.undo))?,
            &PredefinedMenuItem::redo(app, Some(&text.redo))?,
            &PredefinedMenuItem::separator(app)?,
            &PredefinedMenuItem::cut(app, Some(&text.cut))?,
            &PredefinedMenuItem::copy(app, Some(&text.copy))?,
            &PredefinedMenuItem::paste(app, Some(&text.paste))?,
            &PredefinedMenuItem::select_all(app, Some(&text.select_all))?,
        ],
    )?;

    let reload = MenuItem::with_id(app, "reload", &text.reload, true, Some("Cmd+R"))?;
    let view_menu = Submenu::with_items(app, &text.view, true, &[&reload])?;

    let window_menu = Submenu::with_items(
        app,
        &text.window,
        true,
        &[
            &PredefinedMenuItem::minimize(app, Some(&text.minimize))?,
            &PredefinedMenuItem::maximize(app, Some(&text.maximize))?,
        ],
    )?;

    Menu::with_items(
        app,
        &[&app_menu, &file_menu, &edit_menu, &view_menu, &window_menu],
    )
}

pub fn on_event(app: &tauri::AppHandle, id: &str) {
    match id {
        // Handled entirely in Rust: showing the prefs window does not depend on
        // the remote page's IPC being available, so it works on any page.
        "preferences" | "switch_server" => {
            let prefs = app.get_webview_window("prefs");
            if let Some(main) = app.get_webview_window("main") {
                let _ = main.eval(&format!(
                    "console.log('[sure] menu {} -> prefs window present: {}')",
                    id,
                    prefs.is_some()
                ));
            }
            if let Some(w) = prefs {
                let _ = w.show();
                let _ = w.set_focus();
                let _ = w.unminimize();
            }
        }
        "reload" => {
            if let Some(w) = app.get_webview_window("main") {
                let _ = w.eval("window.location.reload()");
            }
        }
        _ => {}
    }
}
