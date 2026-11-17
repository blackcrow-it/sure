import { invoke } from "@tauri-apps/api/core";
import { getCurrentWindow } from "@tauri-apps/api/window";
import { localizePage, stringsFor } from "./strings";
import { shellLocale } from "./locale";
import { serverErrorMessage } from "./status";

interface ServerEntry { url: string; label: string; }
const $ = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;

let { connect: S, preferences: P } = stringsFor(navigator.language);

async function renderServers() {
  let servers: ServerEntry[];
  try {
    servers = await invoke<ServerEntry[]>("list_servers");
  } catch {
    $("prefs-status").textContent = S.loadError;
    return;
  }
  const list = $("prefs-server-list");
  list.innerHTML = "";
  for (const s of servers) {
    const li = document.createElement("li");
    const open = document.createElement("button");
    open.className = "server-open";
    open.textContent = s.label;
    open.setAttribute("aria-label", `${P.switchTo}: ${s.label}`);
    open.addEventListener("click", async () => {
      try {
        await invoke("set_active_server", { url: s.url });
        await getCurrentWindow().hide();
      } catch (err) {
        $("prefs-status").textContent = serverErrorMessage(err, S);
      }
    });
    const rm = document.createElement("button");
    rm.className = "server-remove";
    rm.textContent = S.remove;
    rm.setAttribute("aria-label", `${S.remove}: ${s.label}`);
    rm.addEventListener("click", async (e) => {
      e.stopPropagation();
      try {
        await invoke("remove_server", { url: s.url });
        renderServers();
      } catch (err) {
        $("prefs-status").textContent = serverErrorMessage(err, S);
      }
    });
    li.append(open, rm);
    list.append(li);
  }
}

$("prefs-add").addEventListener("submit", async (e) => {
  e.preventDefault();
  const url = ($("prefs-url") as HTMLInputElement).value.trim();
  if (!url) return;
  $("prefs-status").textContent = S.checking;
  try {
    const base = await invoke<string | null>("check_server", { url });
    if (!base) { $("prefs-status").textContent = S.unreachable; return; }
    await invoke("add_server", { url: base, label: "" });
    ($("prefs-url") as HTMLInputElement).value = "";
    $("prefs-status").textContent = "";
    renderServers();
  } catch (err) {
    $("prefs-status").textContent = serverErrorMessage(err, S);
  }
});

const autostart = $("autostart") as HTMLInputElement;
autostart.addEventListener("change", async () => {
  const enabled = autostart.checked;
  autostart.disabled = true;
  try {
    await invoke("set_launch_at_login", { enabled });
    $("prefs-status").textContent = "";
  } catch {
    autostart.checked = !enabled;
    $("prefs-status").textContent = P.autostartError;
  } finally {
    autostart.disabled = false;
  }
});

async function boot() {
  const locale = await shellLocale();
  ({ connect: S, preferences: P } = stringsFor(locale));
  localizePage(document, locale, "preferences");
  await renderServers();
  try {
    autostart.checked = await invoke<boolean>("get_launch_at_login");
  } catch {
    $("prefs-status").textContent = P.autostartLoadError;
  }
}
boot();
