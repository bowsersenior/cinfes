$(document).ready(function(){
  $('.modal.show-on-domready').modal();

    $('.flip').click(function(){
        $(this).find('.card').addClass('flipped').mouseleave(function(){
            $(this).removeClass('flipped');
        });
        return false;
    });
	
	$('.front img').attr({'width': '600px', 'height': '938px' })
});