var _api = '/api/v1';
var _re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
var _images = {};
var _colours = ['green', 'yellow', 'blue', 'red'];

var _login_modal = new bootstrap.Modal(document.getElementById('login'), { keyboard: true });
var _signup_modal = new bootstrap.Modal(document.getElementById('signup'), { keyboard: true });
var _signup_success_modal = new bootstrap.Modal(document.getElementById('signup_success'), { keyboard: true });

$(document).ready(function() { 
  set_up_authentication();
  set_up_regions();
  set_up_contests();
  set_up_participations();
});



function set_up_participations() {
  $('.participation_save_action').each(function() {
    var p = $(this);
    var id = p.attr('data-id');
    console.log('participations');
   
    p.click(function() {
      var p = {};
      p['status'] = $('.participation-modal-'+id+' .status_participation').val();
      p['region_id'] = $('.participation-modal-'+id+' .region_id_participation').val();
      p['contest_id'] = $('.participation-modal-'+id+' .contest_id_participation').val();
      p['data_source_ids'] = $('.participation-modal-'+id+' .data_sources_participation').val();

console.log(p);

      $.post(_api+'/participation' , { participation: p })
      .done(function(data, status) {
        console.log(data);
        if(data['status']=='fail') {
          //if(data['message']['email']!=undefined) $('#'+id+' .email_unique').removeClass('validation-ok');
          //if(data['message']['organization_name']!=undefined) $('#'+id+' .organization_name_unique').removeClass('validation-ok');
console.log('fail');
        } else {
          reload();
        }
      })
      .fail(function(xhr, status, error) {})
      .always(function() {});
      return false;
    });

  });
}






function set_up_contests() {

  $('.contest_save_action').each(function() {
    var pa = $(this);
    var id = pa.attr('data-id');
    console.log(id);
    var verb = id=='new' ? 'POST' : 'PUT';
    console.log('contests');
   
    pa.click(function() {
      var p = {};
      p['user_id'] = _user_id;
      if(id!='new') p['id'] = parseInt(id);
      p['status'] = $('.contest-modal-'+id+' .status_contest').val();
      p['title'] = $('.contest-modal-'+id+' .title_contest').val();
      p['description'] = $('.contest-modal-'+id+' .description_contest').val();
      p['starts_at'] = $('.contest-modal-'+id+' .starts_at_contest').val();
      p['ends_at'] = $('.contest-modal-'+id+' .ends_at_contest').val();

console.log(p);

      $.ajax({ url: (_api+'/contest'), type: verb, contentType: 'application/json', data: JSON.stringify(p) })
      .done(function(data, status) {
        console.log(data);
        if(data['status']=='fail') {
          //if(data['message']['email']!=undefined) $('#'+id+' .email_unique').removeClass('validation-ok');
          //if(data['message']['organization_name']!=undefined) $('#'+id+' .organization_name_unique').removeClass('validation-ok');
console.log('fail');
        } else {
          reload();
        }
      })
      .fail(function(xhr, status, error) {})
      .always(function() {});
      return false;
    });

  });
}










function set_up_regions() {
  $('#region').on('show.bs.modal', function() { Cookies.set('modal', 'region'); });
  $('#region').on('hide.bs.modal', function() { Cookies.remove('modal'); });

  var images = ['logo', 'header'];

  for( var j = 0 ; j < images.length ; j++ ) {
    $('.'+images[j]+'-region').each(function() {
      var i = $(this);
      var frameid = i.attr('data-frame-id');
      var image = images[j];
      
      i.change(function() { 
        $('.img-fluid.'+image+'-frame-'+frameid).attr('src', URL.createObjectURL(event.target.files[0]));
        getBase64(event.target.files[0], image);
      });
    });  

    $('.'+images[j]+'-region-remove').each(function() {
      var i = $(this);
      var frameid = i.attr('data-frame-id');
      var image = images[j];

      i.click(function() { 
        $('.img-fluid.'+image+'-frame-'+frameid).attr('src', '');
        $('.'+image+'-region.'+image+'-frame-'+frameid).val(null);
      });
    });        
  }

  $('.region_save_action').each(function() {
    var r = $(this);
    var id = r.attr('data-id');
    var verb = id=='new' ? 'POST' : 'PUT';
   
    r.click(function() {
      var p = {};
      p['user_id'] = _user_id;
      if(id!='new') p['id'] = parseInt(id);
      p['status'] = $('.region-modal-'+id+' .status_region').val();
      p['name'] = $('.region-modal-'+id+' .name_region').val();
      p['description'] = $('.region-modal-'+id+' .description_region').val();
      p['population'] = $('.region-modal-'+id+' .population_region').val();
      p['logo_image_url'] = $('.region-modal-'+id+' .logo_url_region').val();
      p['header_image_url'] = $('.region-modal-'+id+' .header_url_region').val();
      p['raw_polygon_json'] = JSON.stringify({ polygons: _polygons });
      p['logo_image'] = _images['logo'];
      p['header_image'] = _images['header'];

       $.ajax({ url: (_api+'/region'), type: verb, contentType: 'application/json', data: JSON.stringify(p) })
      .done(function(data, status) {
        console.log(data);
        if(data['status']=='fail') {
          //if(data['message']['email']!=undefined) $('#'+id+' .email_unique').removeClass('validation-ok');
          //if(data['message']['organization_name']!=undefined) $('#'+id+' .organization_name_unique').removeClass('validation-ok');

        } else {
          reload();
        }
      })
      .fail(function(xhr, status, error) {})
      .always(function() {});
      return false;
    });

  });

  for( var i=0 ; i<_colours.length ; i++ ) {
    $(document).on('click', '#polygon-remove-'+_colours[i], function() {
      var i = parseInt($(this).attr('data-polygon-id'));
      console.log('removing');
      _polygon_objects[i].setMap(null);
      $(this).attr('disabled','disabled');
    });
  }

}

function getBase64(file, name) {
   var reader = new FileReader();
   reader.readAsDataURL(file);
   reader.onload = function () { _images[name] = reader.result; };
   reader.onerror = function (error) { _images[name] = null; };
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
    $('.signup-modal').each(function() {
      var m = $(this);
      if(m.hasClass('show')) get_signup_params(m.attr('id'));
    });
    
    if($('#profile.show').length) get_signup_params('profile');


    if($('#login.show').length && e.key==='Enter') $('#login_action').click();
  });

  $('.signup-modal').each(function() {
    var id = $(this).attr('id');

    $('#'+id+'_action').click(function() { 
      p = get_signup_params(id);

      $.post(_api+'/user' ,p)
      .done(function(data, status) {
        if(data['status']=='fail') {
          if(data['message']['email']!=undefined) $('#'+id+' .email_unique').removeClass('validation-ok');
          if(data['message']['organization_name']!=undefined) $('#'+id+' .organization_name_unique').removeClass('validation-ok');

        } else {
          if(id=='signup') {
            $('#email_login').val($('#signup .email').val());
            _signup_modal.hide();
            _signup_success_modal.show();
          } else {
            reload();
          } 
        }
      })
      .fail(function(xhr, status, error) {})
      .always(function() {});
      return false;
    });
  });   

  $('#profile_action').click(function() { 
    p = get_signup_params('profile');
    $.ajax({ url: (_api+'/user'), type: 'PUT', contentType: 'application/json', data: JSON.stringify(p) })
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

  $('.logout_action').each(function() {
    $(this).click(function() { 
      $.post(_api+'/user/logout')
      .done(function(data, status) {})
      .fail(function(xhr, status, error) {})
      .always(function(){ Cookies.remove('modal'); reload(); });
      return false;
    });  
  });

  $('.close_account_action').each(function() {
    $(this).click(function() { 
      $.ajax({ url: (_api+'/user'), type: 'DELETE', contentType: 'application/json' })
      .done(function(data, status) {})
      .fail(function(xhr, status, error) {})
      .always(function(){ Cookies.remove('modal'); reload(); });
      return false;
    });  
  });




  $('#login input').each(function() { 
    $(this).focus(function() { $('#login span').addClass('validation-ok'); });
  });

  $('.signup-modal').each(function() { 
    var id = $(this).attr('id');
    $('#'+id+' input').each(function() { 
      $(this).focus(function() { $('#'+id+' span').addClass('validation-ok'); });
    });
  });
}

function get_signup_params(modal) {
  var p = {}
  var organization_name = $('#'+modal+' .organization_name');
  var email = $('#'+modal+' .email');
  var password = $('#'+modal+' .password');
  var action = $('#'+modal+'_action');

  p['organization_name'] = organization_name.val().trim();
  p['email'] = email.val().trim().toLowerCase();   
  if(password.length) p['password'] = password.val();

  var all_present = true;
  if(p['organization_name'].length==0) all_present = false;
  if(p['email'].length==0) all_present = false;
  if(password.length && p['password'].length==0) all_present = false;
  if(!all_present) return true;

  var failed = false;
  var organization_name_v = $('#'+modal+' .organization_name_v');
  var email_v = $('#'+modal+' .email_v');
  var password_v = $('#'+modal+' .password_v');  
  if(p['organization_name'].length==0) { organization_name_v.removeClass('validation-ok'); failed = true; } else { organization_name_v.addClass('validation-ok'); }
  if(_re.test(p['email'])==false) { email_v.removeClass('validation-ok'); failed = true; } else { email_v.addClass('validation-ok'); }
  if(password.length && p['password'].length<6) { password_v.removeClass('validation-ok'); failed = true; } else { password_v.addClass('validation-ok'); }

  //if(failed) action.attr('disabled', 'disabled');
  //else action.removeAttr('disabled');

  action.removeAttr('disabled');  

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


