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

  Object.defineProperty(window, "__meetBridge", {
    value: Object.freeze({ version: "0.1.1" }),
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
  }
})();
