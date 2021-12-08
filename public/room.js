(function() {
  var post = document.getElementById('post');
  var posts = document.getElementById('posts');
  var content = document.getElementById('content');
  var csrfs = document.getElementById('post_form');
  var csrf_field = csrfs.getAttribute('data-field');
  var baseUrl = csrfs.getAttribute('data-base-url');

  var jumpToPageBottom = function() {
    content.scrollTop = content.scrollHeight;
  }

  var resize = function() {
    content.style.height = (window.innerHeight - 85) + 'px';
    jumpToPageBottom();
  }

  var add_line = function(s){
    var li = document.createElement('li');
    li.innerText = s;
    posts.appendChild(li);
    jumpToPageBottom();
  }

  resize();
  window.onresize = resize;
  post.focus();

  MessageBus.baseUrl = baseUrl;
  MessageBus.start();
  MessageBus.subscribe(csrfs.getAttribute('data-channel'), function(data){
    data = JSON.parse(data);
    var time = '<' + data.at + '> ';
    if (data.join) {
      add_line(time + data.join + ' joined');
    } else if (data.leave) {
      add_line(time + data.leave + ' left');
    } else {
      add_line(time + data.user + ': ' + data.message);
    }
  });

  serialize = function(obj) {
    var str = [];
    for (var p in obj) {
      if (obj.hasOwnProperty(p)) {
        str.push(encodeURIComponent(p) + "=" + encodeURIComponent(obj[p]));
      }
    }
    return str.join("&");
  }
  var submit_post = function(type, data) {
    data[csrf_field] = csrfs.getAttribute('data-' + type);
    var xhr = new XMLHttpRequest();
    xhr.open('POST', baseUrl+type);
    xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
    xhr.send(serialize(data));
    return xhr;
  }
  submit_post('join', {});

  window.onbeforeunload = function(){
    submit_post('leave', {});
  };

  csrfs.onsubmit = function(e){
    submit_post('message', {"post": post.value});
    post.value = '';
    e.preventDefault();
  };
})();
