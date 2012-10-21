if (typeof window.CINFES === 'undefined') {
  window.CINFES = {}
}

$(document).ready(function(){
  $('.flip').click(function(){
      $(this).find('.card').toggleClass('flipped');
  });

  CINFES.socket = new Pusher('1368c91dfcb03dac81b3');
  CINFES.movie_channel = CINFES.socket.subscribe('movies');

  CINFES.movie_channel.bind('notification', function(data) {
    if (data.type === 'success') {
      toastr.success(data.message);
    } else {
      toastr.info(data.message);
    }
  });

});