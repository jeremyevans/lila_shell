(function() {
  var post = $('#post');
  var posts = $('#posts');
  var content = $('#content');
  var csrfs = $('#post_form');
  var csrf_field = csrfs.data('field');
  var baseUrl = csrfs.data('base-url');

  var resize = function() {
    $('#content').css('height', window.innerHeight-120);
  }

  var jumpToPageBottom = function() {
    content.scrollTop(content.prop("scrollHeight"));
  }

  var add_line = function(s){
    var li = $("<li></li>");
    li.text(s);
    posts.append(li);
    jumpToPageBottom();
  }

  resize();
  $(window).resize(resize);
  jumpToPageBottom();
  post.focus();

  MessageBus.baseUrl = baseUrl;
  MessageBus.start();
  MessageBus.subscribe(csrfs.data('channel'), function(data){
    data = JSON.parse(data);
    if (data.join) {
      add_line('<' + data.at + '> ' + data.join + ' joined');
    } else if (data.leave) {
      add_line('<' + data.at + '> ' + data.leave + ' left');
    } else {
      add_line('<' + data.at + '> ' + data.user + ': ' + data.message);
    }
  });

  var join_data = {};
  join_data[csrf_field] = csrfs.data('join');
  $.post(baseUrl+"join", join_data);

  var leave_data = {};
  leave_data[csrf_field] = csrfs.data('leave');
  window.onbeforeunload = function(){
    $.post(baseUrl+"leave", leave_data);
  };

  $('#post_form').submit(function(e){
    var post_data = {"post": post.val()};
    post_data[csrf_field] = csrfs.data('message');
    $.post(baseUrl+"message", post_data);
    post.val('');
    e.preventDefault();
  });
})();
