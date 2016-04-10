if (typeof window.CINFES === 'undefined') {
  window.CINFES = {}
}

$(document).ready(function(){
  $('.flip').click(function(){
      $(this).find('.card').toggleClass('flipped');
  });

  var pusher = new Pusher('8fdad0b2707f61567c4a', {
    encrypted: true
  });

  CINFES.socket = pusher;
  CINFES.movie_channel = CINFES.socket.subscribe('movies');

  CINFES.movie_channel.bind('notification', function(data) {
    if (data.type === 'success') {
      toastr.success(data.message);
    } else {
      toastr.info(data.message);
    }
  });

});