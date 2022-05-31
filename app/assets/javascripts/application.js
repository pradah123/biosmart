
var _api = '/api/v1';
var _re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
var _images = {};
var _colours = ['green', 'yellow', 'blue', 'red', 'cyan', 'DarkGray', 'DarkMagenta', 'HotPink', 'LawnGreen'];
var _npolygons = 0;
var _polygons = {};

var _login_modal = new bootstrap.Modal(document.getElementById('login'), { keyboard: true });
var _signup_modal = new bootstrap.Modal(document.getElementById('signup'), { keyboard: true });
var _signup_success_modal = new bootstrap.Modal(document.getElementById('signup_success'), { keyboard: true });
var _gallery_modal = new bootstrap.Modal(document.getElementById('gallery'), { keyboard: true });
var _processing_modal = new bootstrap.Modal(document.getElementById('processing_modal'), { keyboard: true });
var _gallery_carousel = null;

var _nshow_more = 1

$(document).ready(function() { 
  set_up_authentication();
  set_up_regions();
  set_up_contests();
  set_up_participations();
  set_up_region_page();
  set_up_contest_page();
  set_up_observations();
  set_up_counters();
});

function reload(atag='') {
  var url = new URL(location.href+(atag.length>0 && location.href.indexOf(atag)==-1 ? '#'+atag : ''));
  window.location = url.href;
  location.reload();
}

function set_up_counters() {
  $('.countdown').each(function() {
    var starts_at = $(this).attr('data-starts-at');
    var id = $(this).attr('data-id');

    var x = setInterval(function() {
      var countDownDate = new Date(starts_at).getTime();
      var now = new Date().getTime();
      var distance = countDownDate - now;
      var days = Math.floor(distance / (1000 * 60 * 60 * 24));
      var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
      var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
      var seconds = Math.floor((distance % (1000 * 60)) / 1000);

      var str = "";
      if(days!=0) str += days + " days ";
      if(days!=0 || hours!=0 ) str += hours + " hours ";
      if( (days!=0 && hours!=0 ) || minutes!=0) str += minutes + " minutes ";
      if( (days!=0 && hours!=0 && minutes!=0) || seconds!=0) str += seconds + " seconds";

      document.getElementById("countdown-"+id).innerHTML = str;
      if (distance<0) { 
        clearInterval(x); 
        document.getElementById("countdown-"+id).innerHTML = ""; 
      } 
    }, 1000);
  });
}

function set_up_observations() {

  $(document).on('click', '.gallery-link', function() { 
    var link = $(this);    
    $('#gallery-carousel').html('');
    var urls = JSON.parse( link.attr('data-image-urls') ); 

    for( var i=0 ; i<urls.length ; i++ ) {
      var html = '<div class="carousel-item"><div class="card border-0 p-0 m-0">';
      html += '<img src="'+urls[i]+'" class="img-fluid" loading="lazy" alt="...">';
      html += '</div></div>';
      $('#gallery-carousel').append(html);
    } 

    $('.carousel-item').first().addClass('active');
    _gallery_modal.show();      
  });

  $('#show_more').click(function() {
    var n = $('.observation').length;
    var params = $(this).attr('data-api-parameters');
    params += "&nstart="+n;
    params += "&nend="+(n + parseInt($(this).attr('data-n-per-fetch')));

    if(n>0 || location.href.indexOf('recent_observations')!=-1) _processing_modal.show();

    $.ajax({ url: ('/observations/more'+params), dataType: 'html' })
    .done(function(data, status) { $('#observations-block').append(data); })
    .fail(function(xhr, status, error) {})
    .always(function() { _processing_modal.hide(); });

    return false;
  });

  $('#search_clear').click(function() { 
    $('#search_input').val(''); $('#search_button').click(); 
  });

  $('#search_button').click(function() {
    var q = $('#search_input').val().toLowerCase().trim();
    Cookies.set('q', q);
    reload('recent_observations');
  });

  $(document).keyup(function(e) {
    if(e.key==='Enter' && $('#search_input').is(':focus')) $('#search_button').click();
  });

  $('.search-for').each(function() { 
    var el = $(this);
    el.click(function(){
      $('#search_input').val(el.text());
      $('#search_button').click();
    });
  });

  $('#search_input').val(Cookies.get('q'));
  $('#show_more').click();
}

function set_up_contest_page() {
  if($('#contest-map').length==0) return; 

  var s = { lat: 0, lng: 0 };
  var map = new google.maps.Map(document.getElementById('contest-map'), { zoom: 2, center: s, controlSize: 20 });
  var infoWindow = new google.maps.InfoWindow({ content: "", disableAutoPan: true, });
    
  google.maps.event.addListenerOnce(map, 'idle', function() { 
    var bounds = new google.maps.LatLngBounds(null);

    if(_participants!=undefined) {
      var markers = [];
      for( var i = 0 ; i<_participants.length ; i++ ) {
        var marker = new google.maps.Marker({ position: _participants[i] });
        marker.setMap(map);
        markers.push(marker);
        bounds.extend(_participants[i]);
        //marker.addListener("click", () => { infoWindow.setContent(label); infoWindow.open(map, marker); });
      }
    }    

    if(bounds.getNorthEast().lat()==-1 && bounds.getSouthWest().lat()==1 && bounds.getNorthEast().lng()==-180 && bounds.getSouthWest().lng()==180) {

    } else {
      map.setCenter(bounds.getCenter());
      map.fitBounds(bounds, 0);
      map.panToBounds(bounds);
    }

    for( var i = 0 ; i<_region_polygons.length ; i++ ) {
      var coordinates = _region_polygons[i]['coordinates'];
      var googlemaps_points = [];
      for( var j = 0 ; j<coordinates.length ; j++ ) googlemaps_points.push({ lng: coordinates[j][0], lat: coordinates[j][1] });
      var polygon = new google.maps.Polygon({ paths: googlemaps_points, fillColor: _colours[i%_colours.length] });
      polygon.setMap(map);
    }  

  });
}

function set_up_region_page() {
  if($('#region-map').length==0) return; 

  var s = { lat: 0, lng: 0 };
  var map = new google.maps.Map(document.getElementById('region-map'), { zoom: 2, center: s, controlSize: 20 });
  var infoWindow = new google.maps.InfoWindow({ content: "", disableAutoPan: true, });
    
  google.maps.event.addListenerOnce(map, 'idle', function() { 
    var bounds = new google.maps.LatLngBounds(null);

    for( var i = 0 ; i<_polygon_json.length ; i++ ) {
      var coordinates = _polygon_json[i]['coordinates'];
      var googlemaps_points = [];
      for( var j = 0 ; j<coordinates.length ; j++ ) googlemaps_points.push({ lng: coordinates[j][0], lat: coordinates[j][1] });
      var polygon = new google.maps.Polygon({ paths: googlemaps_points });
      polygon.setMap(map);

      polygon.getPaths().forEach(function(path) {
        var ar = path.getArray();
        for(var j = 0, l = ar.length; j < l; j++) bounds.extend(ar[j]);  
      });
    }  

    if(bounds.getNorthEast().lat()==-1 && bounds.getSouthWest().lat()==1 && bounds.getNorthEast().lng()==-180 && bounds.getSouthWest().lng()==180) {

    } else {
      map.setCenter(bounds.getCenter());
      map.fitBounds(bounds, 0);
      map.panToBounds(bounds);
    }

    $.get(_api+_observations_filename, function() {})
    .done(function(data, status) {
      console.log(data);
      if(data['data']==undefined || data['data']['observations']==undefined || data['data']['observations'].length==0) {
        
      } else {
        var observations = data['data']['observations']
        var markers = [];
        for( var i = 0 ; i<observations.length ; i++ ) {
          var marker = new google.maps.Marker({ position: observations[i] });
          marker.setMap(map);
          markers.push(marker);
          //marker.addListener("click", () => { infoWindow.setContent(label); infoWindow.open(map, marker); });
        } 
        new markerClusterer.MarkerClusterer(map, markers);//, { 'cssClass': 'marker_cluster' });
      }
    })
    .fail(function(xhr, status, error) {})
    .always(function() {});

    if(location.href.indexOf('show_subregions=true')!=-1) {
      for( var i = 0 ; i<_subregions.length ; i++ ) {
        var circle = new google.maps.Circle({
          strokeColor: "#FF0000",
          strokeOpacity: 0.8,
          strokeWeight: 2,
          fillColor: "#FF0000",
          fillOpacity: 0.35,
          map,
          center: { lat: _subregions[i]['lat'], lng: _subregions[i]['lng'] },
          radius: _subregions[i]['radius_metres']
        });
      } 
    }
  });

}







// edit functions

function set_up_participations() {

  $('.participation_save_action').each(function() {
    var pa = $(this);
    var id = pa.attr('data-id');
    var verb = id=='new' ? 'POST' : 'PUT';
   
    pa.click(function() {
      var p = {};
      if(id!='new') p['id'] = parseInt(id);
      p['user_id'] = _user_id;
      p['status'] = $('.participation-modal-'+id+' .status_participation').val();
      if(p['status']==null) p['status'] = 'submitted';
      p['region_id'] = $('.participation-modal-'+id+' .region_id_participation').val();
      p['contest_id'] = $('.participation-modal-'+id+' .contest_id_participation').val();
      p['data_source_ids'] = [];
      $('input[name="data-sources-'+id+'"]:checked').each(function() { p['data_source_ids'].push(parseInt($(this).val())); });

      $.ajax({ url: (_api+'/participation'), type: verb, contentType: 'application/json', data: JSON.stringify({ 'participation': p }) })
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
    var verb = id=='new' ? 'POST' : 'PUT';
   
    pa.click(function() {
      var p = {};
      p['user_id'] = _user_id;
      if(id!='new') p['id'] = parseInt(id);
      p['status'] = $('.contest-modal-'+id+' .status_contest').val();
      p['title'] = $('.contest-modal-'+id+' .title_contest').val();
      p['description'] = $('.contest-modal-'+id+' .description_contest').val();
      p['starts_at'] = $('.contest-modal-'+id+' .starts_at_contest').val();
      p['ends_at'] = $('.contest-modal-'+id+' .ends_at_contest').val();

      $.ajax({ url: (_api+'/contest'), type: verb, contentType: 'application/json', data: JSON.stringify({ 'contest': p }) })
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
        _images[image] = null;
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
      p['status'] = 'online'; //$('.region-modal-'+id+' .status_region').val();
      p['name'] = $('.region-modal-'+id+' .name_region').val().trim();
      p['description'] = $('.region-modal-'+id+' .description_region').val().trim();
      //p['population'] = $('.region-modal-'+id+' .population_region').val();
      p['logo_image_url'] = $('.region-modal-'+id+' .logo_url_region').val();
      p['header_image_url'] = $('.region-modal-'+id+' .header_url_region').val();
      
      p['logo_image'] = $('img.logo-frame-'+id).attr('src');
      p['logo_image'] = _images['logo']==undefined ? p['logo_image'] : _images['logo'];
      
      p['header_image'] = $('img.header-frame-'+id).attr('src');
      p['header_image'] = _images['header']==undefined ? '' : _images['header'];

      p['raw_polygon_json'] = [];
      $('.region-modal-'+id+' .polygon-json input').each(function() { 
        var val = $(this).val().trim();
        if(val.length) p['raw_polygon_json'].push(val); 
      });

      var failed = false;
      if(p['name'].length==0) { $('.name_region_v').removeClass('validation-ok'); failed = true; } else { $('.name_region_v').addClass('validation-ok'); }
      if(p['description'].length==0) { $('.description_region_v').removeClass('validation-ok'); failed = true; } else { $('.description_region_v').addClass('validation-ok'); }
      if(p['logo_image'].length==0 && p['logo_image_url'].length==0) { $('.logo_region_v').removeClass('validation-ok'); failed = true; } else { $('.logo_region_v').addClass('validation-ok'); }

      for( var i = 0 ; i <p['raw_polygon_json'].length ; i++ ) { 
        if(!validate_polygon_json(p['raw_polygon_json'][i])) { $('.polygon_json_region_v').removeClass('validation-ok'); failed = true; break; }  
        else { $('.polygon_json_region_v').addClass('validation-ok'); }
      }
     
      if(failed==false) {
        p['raw_polygon_json'] = "["+p['raw_polygon_json'].join(',')+"]";

        $.ajax({ url: (_api+'/region'), type: verb, contentType: 'application/json', data: JSON.stringify({ 'region': p }) })
        .done(function(data, status) {
         
          if(data['status']=='fail') {
            console.log(data);
            console.log('in fail')
            //if(data['message']['email']!=undefined) $('#'+id+' .email_unique').removeClass('validation-ok');
            //if(data['message']['organization_name']!=undefined) $('#'+id+' .organization_name_unique').removeClass('validation-ok');

          } else {
            reload();
          }
        })
        .fail(function(xhr, status, error) {})
        .always(function() {});
      }
        
      return false;
    });

  });

  $('.region-modal').each(function() {
    var modalid = $(this).attr('id');

   
    var s = { lat: 0, lng: 0 };
    var map = new google.maps.Map(document.getElementById('map-'+modalid), { zoom: 2, center: s, controlSize: 20 });

    $('#polygon-json-'+modalid+' .polygon-draw').click(function() {
      // validate json
      draw_polygon($(this).parent().find('input'), map);
    });

    var drawingManager = new google.maps.drawing.DrawingManager({
      drawingControl: true,
      drawingControlOptions: { 
        position: google.maps.ControlPosition.TOP_CENTER,
        drawingModes: ['polygon']
      }
    });

    drawingManager.setMap(map);
    google.maps.event.addListener(drawingManager, 'polygoncomplete', write_polygon(modalid));
    
    google.maps.event.addListenerOnce(map, 'idle', function() { 
      var bounds = new google.maps.LatLngBounds(null);

      $('#polygon-json-'+modalid+' .polygon-draw').each(function() { $(this).click(); });

      $('#polygon-json-'+modalid+' .polygon-json input').each(function() {
        var polygon = get_polygon($(this));
        if(polygon!=null) {
          polygon.getPaths().forEach(function(path) {
            var ar = path.getArray();
            for(var i=0, l = ar.length; i <l; i++) bounds.extend(ar[i]);  
          });
        }  
      });

      if(bounds.getNorthEast().lat()==-1 && bounds.getSouthWest().lat()==1 && bounds.getNorthEast().lng()==-180 && bounds.getSouthWest().lng()==180) {

      } else {
        map.setCenter(bounds.getCenter());
        map.fitBounds(bounds, 0);
        map.panToBounds(bounds);
        map.setZoom(6);
      }  
    });
  });

}

function validate_polygon_json(str) {
  try {
    json = JSON.parse(str);

    if(json['type']==null || json['type']==undefined || json['type']!='Polygon') return false;
    if(json['coordinates']==null || json['coordinates']==undefined || !Array.isArray(json['coordinates'])) return false;

    $.each(json['coordinates'], function() {
      var lnglat = $(this);
      if(!Array.isArray(lnglat) || lnglat.length!=2) return false;
      if(typeof(lnglat[0])!='number' || lnglat[0]<-180.0 || lnglat[0]>180.0) return false;
      if(typeof(lnglat[1])!='number' || lnglat[1]<-90.0 || lnglat[1]>90.0) return false;
    });

    return true;
  } catch (e) {
    console.log('thrown in polygon validation');
    console.log(e);
  }
  return false;
}

function write_polygon(modalid) {
  return function(polygon) { 
    var points = polygon.getPath();
    var colour = set_parameters(polygon);
    var geojson_data = [];
    for (var i = 0; i < points.length; i++) geojson_data.push([points.getAt(i).lng(), points.getAt(i).lat()]);
    make_html(geojson_data, modalid, colour, polygon);
  };
}

function set_parameters(polygon) {
  var colour = _colours[_npolygons%_colours.length];
  _npolygons++;
  polygon.setOptions({ fillColor: colour, editable: true });
  return colour;
}

function make_html(polygon_geojson_data, modalid, colour, polygon) {
  var geojson = { 'type': 'Polygon', 'coordinates': polygon_geojson_data };
  var id = '#polygon-json-'+modalid;
  var new_input = $(id+' .polygon-json').first().clone();
  $(id).append(new_input);
  $(id+' .polygon-json input').last().val(JSON.stringify(geojson));
  $(id+' .polygon-json input').last().prop('readonly', true);
  $(id+' .polygon-json button.polygon-remove').last().removeAttr('disabled');
  $(id+' .polygon-json button.polygon-draw').last().prop('disabled', true);
  $(id+' .polygon-json span.polygon-colour').last().css('background-color', colour);
  var row = $(id+' .polygon-json').last();
  $(id+' .polygon-json button.polygon-remove').last().click(function() { 
    polygon.setMap(null); 
    row.remove(); 
  });
}

function draw_polygon(input, map) {
  var polygon = get_polygon(input);
  if(polygon==null) return;

  var colour = set_parameters(polygon);
  polygon.setMap(map);

  input.parent().find('span.polygon-colour').css('background-color', colour);

  input.parent().find('button.polygon-draw').attr('disabled', 'disabled');

  input.parent().find('button.polygon-remove').click(function() { 
    console.log('remove'); 
    polygon.setMap(null); 
    $(this).parent().parent().parent().remove(); 
  });
}

function get_polygon(input) {
  var polygon_text= input.val().trim();
  if(polygon_text.length==0) return null;

  var polygon_json = JSON.parse(polygon_text);
  var coordinates = polygon_json['coordinates'];
  var googlemaps_points = [];
  for( var i = 0 ; i<coordinates.length ; i++ ) googlemaps_points.push({ lng: coordinates[i][0], lat: coordinates[i][1] });
  var polygon = new google.maps.Polygon({ paths: googlemaps_points });

  return polygon;
}

function getBase64(file, name) {
   var reader = new FileReader();
   reader.readAsDataURL(file);
   reader.onload = function () { _images[name] = reader.result; };
   reader.onerror = function (error) { _images[name] = null; };
}












// login etc.

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


