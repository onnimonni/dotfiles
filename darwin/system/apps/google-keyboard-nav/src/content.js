(() => {
  "use strict";

  // -- Selectors (multi-fallback) --
  const SELECTORS = {
    results: ["#rso .MjjYud", "#rso div.g", "#rso div[data-ved]"],
    link: ["a:has(> h3)", ".yuRUbf a"],
    kebab: ['[aria-label="About this result"]', "g-menu-button button"],
    showMore: ["#kp-wp-tab-overview button", '[aria-label="Show more"]'],
    searchInput: ['textarea[name="q"]', 'input[name="q"]'],
  };

  function queryFirst(parent, selectorList) {
    for (const sel of selectorList) {
      const el = parent.querySelector(sel);
      if (el) return el;
    }
    return null;
  }

  function queryAllResults() {
    for (const sel of SELECTORS.results) {
      const els = document.querySelectorAll(sel);
      if (els.length > 0) return Array.from(els);
    }
    return [];
  }

  // -- State --
  // Modes: "idle" | "results" | "kebab" | "showmore" | "searchbar"
  let mode = "idle";
  let currentIndex = -1;
  let results = [];

  // -- DOM helpers --
  function clearHighlights() {
    document.querySelectorAll(".gkn-selected, .gkn-kebab-selected, .gkn-selected-showmore")
      .forEach((el) => el.classList.remove("gkn-selected", "gkn-kebab-selected", "gkn-selected-showmore"));
  }

  function getSearchInput() {
    return queryFirst(document, SELECTORS.searchInput);
  }

  function getShowMore() {
    return queryFirst(document, SELECTORS.showMore);
  }

  function refreshResults() {
    results = queryAllResults();
  }

  function highlightResult(index) {
    clearHighlights();
    if (index >= 0 && index < results.length) {
      results[index].classList.add("gkn-selected");
      results[index].scrollIntoView({ block: "center", behavior: "smooth" });
    }
  }

  function highlightKebab(index) {
    clearHighlights();
    const result = results[index];
    if (!result) return;
    const kebab = queryFirst(result, SELECTORS.kebab);
    if (kebab) {
      kebab.classList.add("gkn-kebab-selected");
      kebab.scrollIntoView({ block: "center", behavior: "smooth" });
    }
  }

  function highlightShowMore() {
    clearHighlights();
    const btn = getShowMore();
    if (btn) {
      btn.classList.add("gkn-selected-showmore");
      btn.scrollIntoView({ block: "center", behavior: "smooth" });
    }
  }

  function focusSearchBar() {
    clearHighlights();
    const input = getSearchInput();
    if (input) {
      input.focus();
      mode = "searchbar";
    }
  }

  // -- Navigation actions --
  function enterResults(index) {
    refreshResults();
    if (results.length === 0) return;
    currentIndex = Math.max(0, Math.min(index, results.length - 1));
    mode = "results";
    highlightResult(currentIndex);
  }

  function moveDown() {
    refreshResults();
    if (mode === "searchbar") {
      const showMore = getShowMore();
      if (showMore) {
        mode = "showmore";
        highlightShowMore();
      } else {
        enterResults(0);
      }
      return;
    }
    if (mode === "showmore") {
      enterResults(0);
      return;
    }
    if (mode === "results" || mode === "idle") {
      if (currentIndex < results.length - 1) {
        currentIndex++;
        mode = "results";
        highlightResult(currentIndex);
      }
    }
  }

  function moveUp() {
    refreshResults();
    if (mode === "results") {
      if (currentIndex > 0) {
        currentIndex--;
        highlightResult(currentIndex);
      } else {
        // At top result, go to show more or search bar
        const showMore = getShowMore();
        if (showMore) {
          mode = "showmore";
          highlightShowMore();
        } else {
          focusSearchBar();
        }
      }
      return;
    }
    if (mode === "showmore") {
      focusSearchBar();
      return;
    }
    if (mode === "kebab") {
      // Exit kebab back to result
      mode = "results";
      highlightResult(currentIndex);
      return;
    }
  }

  function moveLeft() {
    if (mode === "results") {
      const result = results[currentIndex];
      if (!result) return;
      const kebab = queryFirst(result, SELECTORS.kebab);
      if (kebab) {
        mode = "kebab";
        highlightKebab(currentIndex);
      }
    }
  }

  function moveRight() {
    if (mode === "kebab") {
      mode = "results";
      highlightResult(currentIndex);
    }
  }

  function activate() {
    if (mode === "results") {
      const result = results[currentIndex];
      if (!result) return;
      const link = queryFirst(result, SELECTORS.link);
      if (link) link.click();
    } else if (mode === "kebab") {
      const result = results[currentIndex];
      if (!result) return;
      const kebab = queryFirst(result, SELECTORS.kebab);
      if (kebab) kebab.click();
    } else if (mode === "showmore") {
      const btn = getShowMore();
      if (btn) btn.click();
    }
  }

  // -- Keyboard handler --
  function onKeyDown(e) {
    // When search bar is focused, only intercept Down arrow
    const input = getSearchInput();
    if (document.activeElement === input) {
      if (e.key === "ArrowDown") {
        e.preventDefault();
        e.stopPropagation();
        input.blur();
        moveDown();
      }
      // All other keys pass through for text editing
      return;
    }

    // Don't intercept if modifier keys are held (allow browser shortcuts)
    if (e.ctrlKey || e.metaKey || e.altKey) return;

    // Don't intercept if user is typing in some other input/textarea
    const tag = document.activeElement?.tagName;
    if (tag === "INPUT" || tag === "TEXTAREA" || document.activeElement?.isContentEditable) return;

    switch (e.key) {
      case "ArrowDown":
        e.preventDefault();
        moveDown();
        break;
      case "ArrowUp":
        e.preventDefault();
        moveUp();
        break;
      case "ArrowLeft":
        e.preventDefault();
        moveLeft();
        break;
      case "ArrowRight":
        e.preventDefault();
        moveRight();
        break;
      case "Enter":
        if (mode !== "idle") {
          e.preventDefault();
          activate();
        }
        break;
      case "Escape":
        clearHighlights();
        mode = "idle";
        currentIndex = -1;
        break;
    }
  }

  document.addEventListener("keydown", onKeyDown, true);

  // -- MutationObserver for dynamic content --
  const rso = document.getElementById("rso");
  if (rso) {
    const observer = new MutationObserver(() => {
      refreshResults();
      // Re-highlight if current index is still valid
      if (mode === "results" && currentIndex >= 0) {
        if (currentIndex >= results.length) {
          currentIndex = results.length - 1;
        }
        if (currentIndex >= 0) highlightResult(currentIndex);
      }
    });
    observer.observe(rso, { childList: true, subtree: true });
  }

  // Initial scan
  refreshResults();
})();
