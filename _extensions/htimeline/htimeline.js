// htimeline – places the side-panel boxes (box="side") next to their row.
// Each box is centred on the line of its event's row, then pushed up or
// down to stay within the slide; the arrow keeps pointing at the row.
(function () {
  const MARGIN = 40; // px kept free at the bottom of the slide (footer)
  const ARROW_INSET = 14; // px between the arrow and the box corners

  function layoutTimeline(tl) {
    const slide = tl.closest("section");
    if (!slide) return;

    let gridTop = 0;
    for (let el = tl; el && el !== slide; el = el.offsetParent) {
      gridTop += el.offsetTop;
    }
    const slideHeight = Reveal.getComputedSlideSize().height;
    const room = slideHeight - gridTop - MARGIN;

    tl.querySelectorAll(":scope > .htl-event").forEach((ev) => {
      const box = ev.querySelector(":scope > .htl-box");
      const marker = ev.querySelector(":scope > .htl-marker");
      if (!box || !marker) return;

      const h = box.offsetHeight;
      const axis = marker.offsetTop + marker.offsetHeight / 2;
      const top = Math.max(0, Math.min(axis - h / 2, room - h));
      const arrow = Math.max(ARROW_INSET, Math.min(axis - top, h - ARROW_INSET));
      box.style.setProperty("--htl-box-top", top + "px");
      box.style.setProperty("--htl-arrow-y", arrow + "px");
    });
  }

  function layoutSlide(slide) {
    if (!slide) return;
    slide.querySelectorAll(".htimeline.htl-side").forEach(layoutTimeline);
  }

  function init() {
    if (!window.Reveal || !Reveal.on) return;
    const current = () => layoutSlide(Reveal.getCurrentSlide());
    Reveal.on("ready", current);
    Reveal.on("slidechanged", current);
    Reveal.on("resize", current);
    // Images load lazily and change the height of their box.
    document.addEventListener(
      "load",
      (e) => {
        if (e.target.tagName === "IMG" && e.target.closest(".htl-side")) current();
      },
      true
    );
    if (Reveal.isReady()) current();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
