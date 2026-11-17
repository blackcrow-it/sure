import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import * as strings from "../src/strings.ts";
import { serverErrorMessage } from "../src/status.ts";

for (const [input, expected] of [
  ["vi", "vi"], ["vi-VN", "vi"], ["vi_VN", "vi"], ["VI-vn", "vi"],
  ["en-US", "en"], ["fr-FR", "en"], ["", "en"], [undefined, "en"], ["vietnamese", "en"],
]) {
  test(`resolves ${input} to ${expected}`, () => {
    assert.equal(typeof strings.resolveLocale, "function", "locale resolver is available");
    assert.equal(strings.resolveLocale(input), expected);
  });
}

// Use the actual HTML ids so removed/misnamed controls fail the render test.
function pageFixture(name) {
  const html = readFileSync(new URL(`../${name}.html`, import.meta.url), "utf8");
  const nodes = new Map([...html.matchAll(/id="([^"]+)"/g)].map(([, id]) => [id, {
    textContent: "", placeholder: "", attributes: {},
    setAttribute(key, value) { this.attributes[key] = value; },
  }]));
  return { title: "", documentElement: { lang: "en" }, getElementById: (id) => nodes.get(id) };
}

test("Vietnamese connect renders labels, title and remembered servers", () => {
  assert.equal(typeof strings.localizePage, "function", "page localization is available");
  const page = pageFixture("index");
  strings.localizePage(page, "vi-VN", "connect");
  assert.equal(page.documentElement.lang, "vi");
  assert.equal(page.title, "Kết nối với máy chủ Sure của bạn");
  assert.equal(page.getElementById("title").textContent, page.title);
  assert.equal(page.getElementById("connect").textContent, "Tiếp tục");
  assert.equal(page.getElementById("remembered-title").textContent, "Máy chủ đã lưu");
  assert.equal(page.getElementById("url-label").textContent, "Địa chỉ máy chủ");
  assert.equal(page.getElementById("server-url").placeholder, "https://sure.example.com");
});

test("preferences localizes accessible labels and uses English for unsupported locales", () => {
  assert.equal(typeof strings.localizePage, "function", "page localization is available");
  const page = pageFixture("prefs");
  strings.localizePage(page, "vi_VN", "preferences");
  assert.equal(page.title, "Tùy chọn");
  assert.equal(page.getElementById("prefs-title").textContent, "Tùy chọn");
  assert.equal(page.getElementById("autostart-label").textContent, "Khởi động Sure khi đăng nhập");
  assert.equal(page.getElementById("prefs-url").attributes["aria-label"], "Địa chỉ máy chủ");
  strings.localizePage(page, "de-DE", "preferences");
  assert.equal(page.documentElement.lang, "en");
  assert.equal(page.title, "Preferences");
  assert.equal(page.getElementById("prefs-add-btn").textContent, "Add");
});

test("server errors are localized without displaying raw server or keychain diagnostics", () => {
  assert.equal(typeof strings.stringsFor, "function", "dictionary selection is available");
  const vi = strings.stringsFor("vi").connect;
  assert.equal(serverErrorMessage("Invalid server URL: private-value", vi), "Địa chỉ này không hợp lệ.");
  assert.equal(serverErrorMessage("network failed", vi), "Không thể kết nối với máy chủ Sure tại địa chỉ này.");
  assert.equal(serverErrorMessage("Keychain error: private-value", vi), "Không thể lưu thay đổi máy chủ. Vui lòng thử lại.");
  assert.equal(serverErrorMessage("network failed", strings.stringsFor("fr").connect), "Couldn't reach a Sure server at that address.");
});

test("OS language takes precedence, with browser fallback when native locale is unavailable", async () => {
  assert.equal(typeof strings.selectLocale, "function", "native/browser selection is available");
  assert.equal(await strings.selectLocale(async () => "vi_VN", "en-US"), "vi");
  assert.equal(await strings.selectLocale(async () => "fr-FR", "vi-VN"), "en");
  assert.equal(await strings.selectLocale(async () => null, "vi-VN"), "vi");
  assert.equal(await strings.selectLocale(async () => { throw new Error("no IPC"); }, "vi"), "vi");
  assert.equal(await strings.selectLocale(async () => null, "fr-FR"), "en");
});
