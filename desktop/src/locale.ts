import { invoke } from "@tauri-apps/api/core";
import { selectLocale } from "./strings";

export function shellLocale() {
  return selectLocale(
    () => invoke<string>("desktop_locale", { browserLocale: navigator.language }),
    navigator.language,
  );
}
