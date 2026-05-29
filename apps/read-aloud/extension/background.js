// Minimal service worker - relay messages between popup and content scripts
chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  if (msg.action === "getTab") {
    sendResponse({ tabId: sender.tab?.id });
  }
});
