// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.

// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery3
//= require jquery_ujs
//= require turbolinks
//= require jquery.turbolinks
//= require best_in_place
//= require moment
//= require popper
//= require bootstrap-sprockets
//= require twitter/typeahead.min
//= require tokenfield/bootstrap-tokenfield.js
//= require jquery.validate
//= require jquery.validate.additional-methods
//= require jquery-touchswipe/jquery.touchSwipe.min
//= require jquery-creditcardvalidator/jquery.creditCardValidator.js
//= require cable
//= require jquery.mask
//= require fuse/fuse.min
//= require leaflet
//= require clipboard/clipboard
//= require tempusdominus-bootstrap-4.min.js
//= require_tree .


$(document).on('turbolinks:load ready',function() {
  $.jMaskGlobals.watchDataMask = true;
  
  /* Activating Best In Place */
  jQuery(".best_in_place").best_in_place();

  show_ajax_message = function(msg, type) {
    var cssClass = type === 'error' ? 'alert-error' : 'alert-success'
    var html ='<div class="alert ' + cssClass + '">';
    html +='<button type="button" class="close" data-dismiss="alert">&times;</button>';
    html += msg +'</div>';
    
    $("#notifications").html(html);
    // show notifactions in modals too
    if ($("#modal-notifications").length > 0) {
      $("#modal-notifications").html(html);
      //$(".alert" ).fadeOut(5000);
    }
    
  };

  function copyToClipboard(element) {
    var $temp = $("<input>");
    $("body").append($temp);
    $temp.val($(element).text()).select();
    document.execCommand("copy");
    $temp.remove();
  }


  scrollPosition = null;
  
  document.addEventListener('turbolinks:load', function () {
    
    if (scrollPosition) {
      window.scrollTo.apply(window, scrollPosition)
      scrollPosition = null
    }
  }, false)
  
  Turbolinks.reload = function () {
    scrollPosition = [window.scrollX, window.scrollY]
    console.log(scrollPosition);
    Turbolinks.visit(window.location, { action: 'replace', scroll: false })
  }


  $("[data-toggle=popover]").popover();
  // this closes popovers when anything else is clicked.
  $('body').on('click', function (e) {
    //only buttons
    if ($(e.target).data('toggle') !== 'popover'
        && $(e.target).parents('.popover.in').length === 0) { 
        $('[data-toggle="popover"]').popover('hide');
    }
  });

  $(document).ajaxComplete(function(event, request) {
    var msg = request.getResponseHeader('X-Message');
    var type = request.getResponseHeader('X-Message-Type');

    if (type !== null) {
      show_ajax_message(msg, type);
    }
  });

  $('body').keydown(function (e) {
    if ($('#gift-card-modal').is(':visible')) {
        var rx = /INPUT|SELECT|TEXTAREA/i;
        if (e.keyCode == 8) {
            if(!rx.test(e.target.tagName) || e.target.disabled || e.target.readOnly ){
                e.preventDefault();
            }
        }
    }
});

});
