$(document).ready(function(){
  $('.modal.show-on-domready').modal();

  $('.flip').click(function(){
      $(this).find('.card').toggleClass('flipped');
      return false;
  });
});