// Injected into the page world of meet.google.com at document start.
// Owns the JS side of the native bridge.
//
// Note: no getDisplayMedia polyfill — macOS 26 WebKit supports screen
// sharing natively in embedded web views (verified 2026-08-04; the M3
// spike diagnostics are in git history).
(() => {
  "use strict";
  if (window.__meetBridge) return;

  const post = (message) => {
    try {
      window.webkit.messageHandlers.meetBridge.postMessage(message);
    } catch (e) {
      // Handler not installed (e.g. subframe); nothing to do.
    }
  };

  // Separate handler: page->app mirroring of Meet's own control state, which
  // is per-page, unlike the shared meetBridge events.
  const postState = (message) => {
    try {
      window.webkit.messageHandlers.meetState.postMessage(message);
    } catch (e) {
      // Handler not installed (e.g. subframe); nothing to do.
    }
  };

  // Replays a keystroke in the page so native menu items can drive Meet's own
  // keyboard handlers. Returns whether anything called preventDefault, a rough
  // "Meet handled it" signal for the native log.
  const dispatchKey = (chord) => {
    const target = document.activeElement ?? document.body;
    const init = { bubbles: true, cancelable: true, composed: true, ...chord };
    const down = new KeyboardEvent("keydown", init);
    // keyCode/which are read-only and not always honored by the constructor;
    // pin them for handlers that still read the legacy fields.
    if (chord.keyCode && down.keyCode !== chord.keyCode) {
      for (const name of ["keyCode", "which"]) {
        Object.defineProperty(down, name, { get: () => chord.keyCode });
      }
    }
    target.dispatchEvent(down);
    target.dispatchEvent(new KeyboardEvent("keyup", init));
    return down.defaultPrevented;
  };

  Object.defineProperty(window, "__meetBridge", {
    value: Object.freeze({ version: "0.1.1", dispatchKey }),
  });

  // WebPage has no native window.open hook, so popups (attached Docs, chat
  // links) are routed through the bridge instead.
  window.open = (url) => {
    if (url) post({ type: "openWindow", url: new URL(url, location.href).href });
    return null;
  };

  document.addEventListener("DOMContentLoaded", () => {
    post({ type: "ready", url: location.href });
  });

  // ---- Hide self view ------------------------------------------------------
  // Port of Cryptacular/google-meet-hide-self: once others join a call,
  // drive Meet's own UI to minimize the self tile, then close the floating
  // preview. Gated by window.__snugHideSelf (set natively from the
  // preference before this script runs; updated live when it changes).
  if (location.host === "meet.google.com") {
    const byXPath = (xpath) =>
      document
        .evaluate(xpath, document, null, XPathResult.ANY_TYPE, null)
        .iterateNext();
    const isOnJoinPage = () => !!byXPath("//i[contains(., 'phone_forwarded')]");
    const moreButton = () =>
      byXPath("//i[contains(., 'visual_effects')]/following::i[contains(., 'more_vert')]");
    const hideSelfButton = () =>
      byXPath("//span[i[contains(., 'close_fullscreen')]]");
    const closeSendingVideoButton = () =>
      byXPath("//button[i[contains(., 'close')]]");
    const areOthersInTheCall = () =>
      document.getElementsByTagName("video").length > 1;

    // Keyed by path so SPA navigation to a new meeting re-arms the one-shot.
    let hiddenForPath = null;
    setInterval(() => {
      if (!window.__snugHideSelf) return;
      if (hiddenForPath === location.pathname) return;
      if (isOnJoinPage() || !areOthersInTheCall()) return;
      const more = moreButton();
      if (!more) return;
      hiddenForPath = location.pathname;
      more.click();
      setTimeout(() => hideSelfButton()?.click(), 200);
      setTimeout(() => closeSendingVideoButton()?.click(), 4000);
    }, 2000);

    // ---- Mirror Meet's mic state --------------------------------------------
    // Meet's own button is the only reliable source: WebKit's
    // microphoneCaptureState reports platform capture and stays active while
    // Meet is muted. The icon ligature identifies the button independently of
    // UI language; data-is-muted carries the state when Meet provides it.
    let micButton = null;

    const findMicButton = () => {
      for (const icon of document.querySelectorAll("i")) {
        const name = icon.textContent.trim();
        if (name !== "mic" && name !== "mic_off") continue;
        const button =
          icon.closest("[data-is-muted]") ?? icon.closest('[role="button"]');
        if (button) return button;
      }
      return null;
    };

    // True/false while a mic control exists, null when there is none to read.
    const readMicMuted = () => {
      if (!micButton?.isConnected) micButton = findMicButton();
      if (!micButton) return null;
      const flag = micButton.getAttribute("data-is-muted");
      if (flag !== null) return flag === "true";
      return micButton.querySelector("i")?.textContent.trim() === "mic_off";
    };

    // Polled rather than observed: Meet's DOM churns constantly, so a filtered
    // MutationObserver would still need this fallback for the button appearing
    // and disappearing. Posts only on change, so idle cost is one read a tick.
    let lastMuted;
    setInterval(() => {
      const muted = readMicMuted();
      if (muted === lastMuted) return;
      lastMuted = muted;
      postState({ type: "microphone", muted });
    }, 500);
  }
})();
