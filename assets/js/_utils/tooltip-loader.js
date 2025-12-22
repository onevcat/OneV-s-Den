/**
 * Initial Bootstrap Tooltip.
 * v2.0
 * https://github.com/cotes2020/jekyll-theme-chirpy
 * © 2019 Cotes Chung
 * MIT License
*/
$(function () {
  if (typeof $.fn.tooltip !== "function") {
    return;
  }

  $("[data-toggle=\"tooltip\"]").tooltip();
});
