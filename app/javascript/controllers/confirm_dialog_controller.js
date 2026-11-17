import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="confirm-dialog"
// See javascript/controllers/application.js for how this is wired up
export default class extends Controller {
  static targets = ["title", "subtitle", "confirmButton"];

  static values = { confirm: String, title: String, body: String };

  handleConfirm(rawData) {
    const data = this.#normalizeRawData(rawData);

    this.#prepareDialog(data);

    this.element.returnValue = "";
    this.element.showModal();

    return new Promise((resolve) => {
      this.element.addEventListener(
        "close",
        () => {
          const isConfirmed = this.element.returnValue === "confirm";
          resolve(isConfirmed);
        },
        { once: true },
      );
    });
  }

  #prepareDialog(data) {
    const variant = data.variant || "primary";

    this.confirmButtonTargets.forEach((button) => {
      if (button.dataset.variant === variant) {
        button.removeAttribute("hidden");
      } else {
        button.setAttribute("hidden", true);
      }

      button.textContent = data.confirmText || this.confirmValue;
    });

    this.titleTarget.textContent = data.title || this.titleValue;
    // Text, never HTML: bodies interpolate record names (merchants, accounts,
    // brokerages, tickers) that come from bank feeds, providers and other
    // family members, however the caller built the confirmation.
    this.subtitleTarget.textContent = data.body || this.bodyValue;
  }

  // If data is a string, it's the title.  Otherwise, return the parsed object.
  #normalizeRawData(rawData) {
    try {
      const parsed = JSON.parse(rawData);

      if (typeof parsed === "boolean") {
        return { title: this.titleValue };
      }

      return parsed;
    } catch (e) {
      return { title: rawData };
    }
  }
}
