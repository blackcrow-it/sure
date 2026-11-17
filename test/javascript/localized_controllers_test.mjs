import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import vm from "node:vm";

async function controller(name, globals = {}) {
  const source = await readFile(new URL(`../../app/javascript/controllers/${name}_controller.js`, import.meta.url), "utf8");
  const context = vm.createContext({ Controller: class {}, ...globals });
  vm.runInContext(source.replace(/^import .*?;?\r?\n/gm, "").replace("export default class", "globalThis.Subject = class"), context);
  return new context.Subject();
}

test("confirmation uses translated server defaults and preserves supplied content", async () => {
  const subject = await controller("confirm_dialog");
  let close;
  subject.element = { showModal() {}, addEventListener(_event, callback) { close = callback; } };
  subject.titleTarget = {};
  subject.subtitleTarget = {};
  subject.confirmButtonTargets = [{ dataset: { variant: "primary" }, removeAttribute() {}, setAttribute() {} }];
  subject.confirmValue = "Xác nhận";
  subject.titleValue = "Bạn có chắc chắn không?";
  subject.bodyValue = "Không thể hoàn tác thao tác này.";
  const confirmation = subject.handleConfirm("true");
  assert.equal(subject.titleTarget.textContent, subject.titleValue);
  assert.equal(subject.subtitleTarget.textContent, subject.bodyValue);
  assert.equal(subject.confirmButtonTargets[0].textContent, "Xác nhận");
  subject.element.returnValue = "confirm";
  close();
  assert.equal(await confirmation, true);

  const custom = subject.handleConfirm(JSON.stringify({ title: "A < B", body: "Tên do người dùng nhập" }));
  assert.equal(subject.titleTarget.textContent, "A < B");
  assert.equal(subject.subtitleTarget.textContent, "Tên do người dùng nhập");
  subject.element.returnValue = "cancel";
  close();
  assert.equal(await custom, false);
});

test("file upload keeps the filename literal inside translated status", async () => {
  const subject = await controller("file_upload");
  const label = {};
  subject.hasFileNameTarget = true;
  subject.hasInputTarget = true;
  subject.hasUploadAreaTarget = false;
  subject.inputTarget = { files: [{ name: "$&-sao-kê.csv" }] };
  subject.fileNameTarget = { querySelector(selector) { return selector === "p" ? label : null; } };
  subject.uploadingValue = "Đang tải lên %{name}...";
  subject.formSubmitting();
  assert.equal(label.textContent, "Đang tải lên $&-sao-kê.csv...");
});

test("invalid drop shows the localized validation message", async () => {
  let message;
  const subject = await controller("drag_and_drop_import", { alert(value) { message = value; } });
  subject.overlayTarget = { classList: { add() {} } };
  subject.invalidFileValue = "Vui lòng tải lên tệp CSV hợp lệ.";
  subject.drop({ preventDefault() {}, dataTransfer: { files: [{ name: "image.png", type: "image/png" }] } });
  assert.equal(message, subject.invalidFileValue);
});
