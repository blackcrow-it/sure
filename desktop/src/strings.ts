import en from "./locales/en.json";
import vi from "./locales/vi.json";

export type Locale = "en" | "vi";
export type Strings = typeof en;

const dictionaries: Record<Locale, Strings> = { en, vi };

export function resolveLocale(locale?: string | null): Locale {
  return locale?.trim().split(/[-_]/)[0].toLowerCase() === "vi" ? "vi" : "en";
}

export function stringsFor(locale?: string | null): Strings {
  return dictionaries[resolveLocale(locale)];
}

export async function selectLocale(readNative: () => Promise<string | null>, browserLocale: string): Promise<Locale> {
  try {
    return resolveLocale(await readNative() || browserLocale);
  } catch {
    return resolveLocale(browserLocale);
  }
}

// Only local shell pages use this renderer. The embedded server owns its lang,
// title and account preference; neither the bridge nor navigation changes them.
export function localizePage(document: Document, locale: string, page: "connect" | "preferences") {
  const { connect: S, preferences: P } = stringsFor(locale);
  document.documentElement.lang = resolveLocale(locale);
  document.title = page === "connect" ? S.title : P.title;
  const labels = page === "connect"
    ? { title: S.title, "url-label": S.serverLabel, connect: S.connect, "remembered-title": S.remembered }
    : { "prefs-title": P.title, "servers-title": P.servers, "prefs-add-btn": P.add, "autostart-label": P.launchAtLogin };
  for (const [id, text] of Object.entries(labels)) {
    document.getElementById(id)!.textContent = text;
  }
  const input = document.getElementById(page === "connect" ? "server-url" : "prefs-url") as HTMLInputElement;
  input.placeholder = S.urlPlaceholder;
  input.setAttribute("aria-label", S.serverLabel);
}
