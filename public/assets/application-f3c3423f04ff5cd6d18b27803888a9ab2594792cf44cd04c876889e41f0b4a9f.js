var _api = 'http://localhost:3000/api/v1';
var _re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;

$(document).ready(function() { 

  var url_params = new URLSearchParams(window.location.search);
  if(url_params.has('q')) Cookies.set('q', url_params.get('q'));

  $('#search input').val(Cookies.get('q'));

  $('#search button').click(search);

  $(document).keyup(function(e) {
    if(e.key==='Enter' && $('#search input').is(':focus')) search();
    else {
      if($('#shortname_signup').is(':focus')) check_shortname_uniqueness('signup');
      if($('#shortname_profile').is(':focus')) check_shortname_uniqueness('profile');

      if($('#signup.show').length) get_params('signup');
      if($('#profile.show').length) get_params('profile');

      if($('#login.show').length && e.key==='Enter') $('#login_action').click();
    }
  });

  
  $('#signup').on('show.bs.modal', function() { Cookies.set('modal', 'signup'); });
  $('#login').on('show.bs.modal', function() { Cookies.set('modal', 'login'); });
  $('#profile').on('show.bs.modal', function() { Cookies.set('modal', 'profile'); });
  $('#signup').on('hide.bs.modal', function() { Cookies.remove('modal'); });
  $('#login').on('hide.bs.modal', function() { Cookies.remove('modal'); });
  $('#profile').on('hide.bs.modal', function() { Cookies.remove('modal'); });

  $('#already_have_an_account').click(function() { $('#signup .btn-close').click(); $('#login_button').click(); });

  $('#signup_from_login').click(function() { $('#login .btn-close').click(); $('#signup_button').click(); });

  $('#signup_action').click(function() { 
    p = get_params('signup');
    $.post(_api+'/user' ,p)
    .done(function(data, status) {})
    .fail(function(xhr, status, error) {})
    .always(function(){ reload(); });
    return false;
  }); 

  $('#profile_action').click(function() { 
    p = get_params('profile');
    $.ajax({ url: (_api+'/user') , type: 'PUT', contentType: 'application/json', data: JSON.stringify(p) })
    .done(function(data, status) {})
    .fail(function(xhr, status, error) {})
    .always(function(){ reload(); });
    return false;
  });

  $('#login_action').click(function(){ 
    var p ={};
    p['email'] = $('#email_login').val();
    p['password'] = $('#password_login').val();
    login(p);
    return false;
  });

  $('#onetime_action').click(function() {
    p = {}
    p['email'] = $('#email_onetime').val();
    p['path'] = window.location.pathname; 
    $.post(_api+'/user/request-onetime-login-code', p)
    .done(function(data, status) {})
    .fail(function(xhr, status, error) {})
    .always(function() { 
      $('#login .btn-close').click();
    });
    return false;
  });

  $('#logout_action').click(function() { 
    $.post(_api+'/user/logout')
    .done(function(data, status) {})
    .fail(function(xhr, status, error) {})
    .always(function(){ Cookies.remove('modal'); reload(); });
    return false;
  });

  $('#login input').each(function() { 
    $(this).focus(function() { $('#login span.small').addClass('validation-ok'); });
  });

  $('#signup input').each(function() { 
    $(this).focus(function() { $('#signup span.small').addClass('validation-ok'); });
  });


console.log('here');
  $('#toggle_password').click(function() {
    console.log($(this).attr('type'));

    $(this).attr( 'type', ($(this).attr('type')=='password' ? 'text' : 'password') );
  });





  var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
  var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) { return new bootstrap.Tooltip(tooltipTriggerEl) });

  if(_user_status=='opened') {
    var modal = (new bootstrap.Modal(document.getElementById('signup_success'), {})).show();

  } else {
    var modal_name = Cookies.get('modal');
    if(modal_name!=undefined) (new bootstrap.Modal(document.getElementById(modal_name), {})).show();
  }

  var params = new URLSearchParams(window.location.search);
  if(_user_status=='' && params.get('code')!=null) {
    var p = {};
    p['code'] = params.get('code');
    login(p); 
  }
});

function check_shortname_uniqueness(modal) {
  var m = modal;
  var p = {}
  p['shortname'] = $('#shortname_'+m).val().trim();
  $.post(_api+'/user/shortname', p)
  .done(function(data, status) { 
    if(data.data.unique==false) $('#'+m+' .shortname_unique').removeClass('validation-ok');
    else $('#'+m+' .shortname_unique').addClass('validation-ok');
  })
  .fail(function(xhr, status, error) { });
}

function get_params(modal) {
  var p = {}
  p['shortname'] = $('#shortname_'+modal).val().trim();
  p['firstname'] = $('#firstname_'+modal).val().trim(); 
  p['lastname'] = $('#lastname_'+modal).val().trim();
  p['email'] = $('#email_'+modal).val().trim().toLowerCase();   
  p['password'] = $('#email_'+modal).val();

  var failed = false;
  if(p['shortname'].length==0) { $('#'+modal+' .shortname').removeClass('validation-ok'); failed = true; }
  if(p['firstname'].length==0) { $('#'+modal+' .firstname').removeClass('validation-ok'); failed = true; }
  if(p['lastname'].length==0) { $('#'+modal+' .lastname').removeClass('validation-ok'); failed = true; }
  if(_re.test(p['email'])==false) { $('#'+modal+' .email').removeClass('validation-ok'); failed = true; }
  if(p['password'].length<6) { $('#'+modal+' .password').removeClass('validation-ok'); failed = true; }

  if(failed) $('#'+modal+'_action').attr('disabled', 'disabled');
  else $('#'+modal+'_action').removeAttr('disabled');

  return (failed ? null : p);
}    

function reload() {
  var url = new URL(location.href);
  url.search = '';
  window.location = url.href;
}

function search() {
  var q = $('#search input').val().trim();
  Cookies.set('q', q);
  if(q.length>0) location.href = "/search?q="+encodeURIComponent(q);
}

function login(params) {
  $.post(_api+'/user/login', params)
  .done(function(data, status) { 
    if(data.status=='fail') $('#login .validation-ok').removeClass('validation-ok');
    else { Cookies.remove('modal'); reload(); }
  })
  .fail(function(xhr, status, error) {
    $('#login .validation-ok').removeClass('validation-ok');
  });  
}

;
