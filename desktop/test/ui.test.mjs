import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { runInNewContext } from "node:vm";
import test from "node:test";
import ts from "typescript";

const root = fileURLToPath(new URL("..", import.meta.url));
const flush = () => new Promise((resolve) => setImmediate(resolve));

// Only the DOM and IPC boundary are doubled; execute the real entrypoint,
// dictionary, locale selection, event handlers and error mapping together.
async function launch(page, { language = "vi-VN", native = "vi", handlers = {} } = {}) {
  function element() {
    return {
      textContent: "", value: "", checked: false, disabled: false, attributes: {},
      children: [], events: {}, dataset: {}, classList: { add() {}, remove() {} },
      set innerHTML(_) { this.children = []; },
      setAttribute(key, value) { this.attributes[key] = value; },
      addEventListener(name, handler) { this.events[name] = handler; },
      append(...children) { this.children.push(...children); },
    };
  }
  const html = readFileSync(resolve(root, page === "main" ? "index.html" : "prefs.html"), "utf8");
  const nodes = new Map([...html.matchAll(/id="([^"]+)"/g)].map(([, id]) => [id, element()]));
  const document = {
    title: "Sure", documentElement: { lang: "en" },
    getElementById: (id) => nodes.get(id), createElement: () => element(),
  };
  const navigation = [];
  const window = { location: { assign: (url) => navigation.push(url) } };
  const defaults = { desktop_locale: () => native, active_server: () => null, list_servers: () => [], get_launch_at_login: () => false };
  const invoke = async (command, args) => {
    const handler = handlers[command] ?? defaults[command];
    assert.ok(handler, `unexpected IPC command ${command}`);
    return handler(args);
  };
  const cache = new Map();
  function load(path) {
    if (cache.has(path)) return cache.get(path).exports;
    if (path.endsWith(".json")) return JSON.parse(readFileSync(path, "utf8"));
    const module = { exports: {} };
    cache.set(path, module);
    const source = readFileSync(path, "utf8").replaceAll("import.meta.url", JSON.stringify(pathToFileURL(path).href));
    const code = ts.transpileModule(source, {
      compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2021, esModuleInterop: true },
    }).outputText;
    const require = (name) => {
      if (name === "@tauri-apps/api/core") return { invoke };
      if (name === "@tauri-apps/api/event") return { listen: async () => () => {} };
      if (name === "@tauri-apps/api/window") return { getCurrentWindow: () => ({ hide: async () => {} }) };
      return load(resolve(dirname(path), name.endsWith(".json") ? name : `${name}.ts`));
    };
    runInNewContext(code, { module, exports: module.exports, require, document, window, navigator: { language }, URL, console });
    return module.exports;
  }
  load(resolve(root, `src/${page}.ts`));
  await flush();
  return { document, navigation, node: (id) => nodes.get(id), async event(node, name) {
    await node.events[name]({ preventDefault() {}, stopPropagation() {} });
    await flush();
  } };
}

test("onboarding renders Vietnamese remembered actions and reports remove failures", async () => {
  const ui = await launch("main", { handlers: {
    list_servers: () => [{ label: "Home <server>", url: "https://home.test/sure" }],
    remove_server: () => { throw "Keychain error: detail"; },
  } });
  assert.equal(ui.document.title, "Kết nối với máy chủ Sure của bạn");
  const [open, remove] = ui.node("server-list").children[0].children;
  assert.equal(open.textContent, "Home <server>");
  assert.equal(remove.textContent, "Xóa");
  assert.equal(remove.attributes["aria-label"], "Xóa: Home <server>");
  await ui.event(remove, "click");
  assert.equal(ui.node("status").textContent, "Không thể lưu thay đổi máy chủ. Vui lòng thử lại.");
});

test("connection errors use selected locale and successful navigation preserves server URL", async () => {
  const ui = await launch("main", { handlers: {
    check_server: ({ url }) => {
      if (url === "bad") throw "Invalid server URL: detail";
      return "https://home.test/sure";
    },
    add_server: () => [{ url: "https://home.test/sure", label: "Home" }],
    set_active_server: ({ url }) => assert.equal(url, "https://home.test/sure"),
  } });
  ui.node("server-url").value = "bad";
  await ui.event(ui.node("server-form"), "submit");
  assert.equal(ui.node("status").textContent, "Địa chỉ này không hợp lệ.");
  ui.node("server-url").value = "https://home.test/sure";
  await ui.event(ui.node("server-form"), "submit");
  assert.deepEqual(ui.navigation, ["https://home.test/sure/"]);
});

test("preferences translates buttons, accessible names and autostart failure", async () => {
  const ui = await launch("prefs", { handlers: {
    list_servers: () => [{ label: "Home", url: "https://home.test" }],
    set_launch_at_login: () => { throw "OS failure"; },
  } });
  assert.equal(ui.document.documentElement.lang, "vi");
  assert.equal(ui.document.title, "Tùy chọn");
  assert.equal(ui.node("prefs-url").attributes["aria-label"], "Địa chỉ máy chủ");
  assert.equal(ui.node("prefs-server-list").children[0].children[0].attributes["aria-label"], "Chuyển đến: Home");
  ui.node("autostart").checked = true;
  await ui.event(ui.node("autostart"), "change");
  assert.equal(ui.node("autostart").checked, false);
  assert.equal(ui.node("prefs-status").textContent, "Không thể cập nhật tùy chọn khởi động khi đăng nhập. Vui lòng thử lại.");
});

test("browser Vietnamese is used without IPC and unsupported language renders English", async () => {
  const browser = await launch("main", { language: "vi_VN", handlers: {
    desktop_locale: () => { throw "not running in Tauri"; },
  } });
  assert.equal(browser.node("connect").textContent, "Tiếp tục");
  const fallback = await launch("prefs", { native: "fr-FR", language: "fr-FR" });
  assert.equal(fallback.document.documentElement.lang, "en");
  assert.equal(fallback.node("prefs-add-btn").textContent, "Add");
});

test("resuming a saved server does not add a locale query or change the saved address", async () => {
  const ui = await launch("main", { handlers: { active_server: () => "https://home.test/nested/sure" } });
  assert.deepEqual(ui.navigation, ["https://home.test/nested/sure/"]);
});
