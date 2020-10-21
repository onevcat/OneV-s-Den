/*
Reference: https://bootsnipp.com/snippets/featured/link-to-top-page
*/
$(window).scroll(function() {
  if ($(this).scrollTop() > 50
      && $("#sidebar-trigger").css("display") === "none") {
    $("#back-to-top").fadeIn();
  } else {
    $("#back-to-top").fadeOut();
  }
});

$(function() {
  $("#back-to-top").click(function() {
    $("body,html").animate({scrollTop: 0}, 800);
    return false;
  });
});