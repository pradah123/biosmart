var _api = '/api/v1';
var _re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;

var _login_modal = new bootstrap.Modal(document.getElementById('login'), { keyboard: true });
var _signup_modal = new bootstrap.Modal(document.getElementById('signup'), { keyboard: true });
var _signup_success_modal = new bootstrap.Modal(document.getElementById('signup_success'), { keyboard: true });

$(document).ready(function() { 
  set_up_authentication();
  set_up_regions();
});











function set_up_regions() {
  $('#region').on('show.bs.modal', function() { Cookies.set('modal', 'region'); });
  $('#region').on('hide.bs.modal', function() { Cookies.remove('modal'); });


}
















function set_up_authentication() {
  $('#signup').on('show.bs.modal', function() { Cookies.set('modal', 'signup'); });
  $('#login').on('show.bs.modal', function() { Cookies.set('modal', 'login'); });
  $('#profile').on('show.bs.modal', function() { Cookies.set('modal', 'profile'); });
  $('#signup').on('hide.bs.modal', function() { Cookies.remove('modal'); });
  $('#login').on('hide.bs.modal', function() { Cookies.remove('modal'); });
  $('#profile').on('hide.bs.modal', function() { Cookies.remove('modal'); });

  $('#already_have_an_account').click(function() { _signup_modal.hide(); _login_modal.show(); });
  $('#signup_from_login').click(function() { _login_modal.hide(); _signup_modal.show(); });
  $('#signup_success').on('hide.bs.modal', function() { _login_modal.show(); });

  $(document).keyup(function(e) {
    if($('#signup.show').length) get_params('signup');
    if($('#profile.show').length) get_params('profile');
    if($('#login.show').length && e.key==='Enter') $('#login_action').click();
  });

  $('#signup_action').click(function() { 
    p = get_params('signup');
    $.post(_api+'/user' ,p)
    .done(function(data, status) {
      console.log(data);
      if(data['status']=='fail') {
        if(data['message']['email']!=undefined) ;
        if(data['message']['organization_name']!=undefined) ;

      } else {
        $('#email_login').val($('#email_signup').val());
        _signup_modal.hide();
        _signup_success_modal.show();
      }
      console.log(">> in signup");
    })
    .fail(function(xhr, status, error) {})
    .always(function() {});
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

  $('#logout_action').click(function() { 
    $.post(_api+'/user/logout')
    .done(function(data, status) {})
    .fail(function(xhr, status, error) {})
    .always(function(){ Cookies.remove('modal'); reload(); });
    return false;
  });

  $('#login input').each(function() { 
    $(this).focus(function() { $('#login span').addClass('validation-ok'); });
  });

  $('#signup input').each(function() { 
    $(this).focus(function() { $('#signup span').addClass('validation-ok'); });
  });  
}

function get_params(modal) {
  var p = {}
  p['organization_name'] = $('#organization_name_'+modal).val().trim();
  p['email'] = $('#email_'+modal).val().trim().toLowerCase();   
  if(modal!='profile') p['password'] = $('#password_'+modal).val();

  var all_present = true;
  if(p['organization_name'].length==0) all_present = false;
  if(p['email'].length==0) all_present = false;
  if(modal!='profile' && p['password'].length==0) all_present = false;
  if(!all_present) return true;

  var failed = false;
  if(p['organization_name'].length==0) { $('#'+modal+' .organization_name').removeClass('validation-ok'); failed = true; } else { $('#'+modal+' .organization_name').addClass('validation-ok'); }
  if(_re.test(p['email'])==false) { $('#'+modal+' .email').removeClass('validation-ok'); failed = true; } else { $('#'+modal+' .email').addClass('validation-ok'); }
  if(modal!='profile' && p['password'].length<6) { $('#'+modal+' .password').removeClass('validation-ok'); failed = true; } else { $('#'+modal+' .password').addClass('validation-ok'); }

  if(failed) $('#'+modal+'_action').attr('disabled', 'disabled');
  else $('#'+modal+'_action').removeAttr('disabled');

  p = { 'user': p };

  return (failed ? null : p);
}

function reload() {
  var url = new URL(location.href);
  window.location = url.href;
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


