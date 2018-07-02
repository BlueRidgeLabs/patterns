$(document).on('page:load turbolinks:load ready ajax:complete', function() {
  assign_cards_to_user = function(){
    var user_id = document.getElementById('select_user_for_cards').value;
    var checked = $('input:checked[name="card_activation_id_change[]"]').map(function() {
      return parseInt(this.value);
    }).get().join()
    
    if (checked.length > 0) {
      url = '/card_activations/change_user/'+checked;
      $.ajax({type: "POST",url: url,data:{user_id: user_id}});
    }
  }

  function update_checkbox_count(){
    var checked_count = $('#card-activations-large tr input[type="checkbox"]:checked:visible').length
    $('#checkedcount').html(checked_count);
  }
  
  $(':checkbox').on('click', update_checkbox_count)

  $('#card-all').on('click',function(){
    $('#card-activations-large tr input[type="checkbox"]:visible').prop('checked', this.checked);
    update_checkbox_count();
  });

  
  var attr_sort_state = {'user-name':false, 'sequence-number':false}
  var cur_attr = 'user-name';

  function toggleSortState(attr){
    if (attr_sort_state[attr]) {
     attr_sort_state[attr] = false; 
    } else {
     attr_sort_state[attr] = true; 
    }
  }

  function sortTableAttr(a,b){
    var A = $(a).data(cur_attr);
    var B = $(b).data(cur_attr);
    if (attr_sort_state[cur_attr]) {
      if (A > B) return 1;
      if( A < B) return -1;
    } else {
      if (A > B) return -1;
      if( A < B) return 1;
    }
      return 0;
  }

  $("#sequence-title").on('click', function(){
    cur_attr = 'sequence-number'
    var rows = $("#card-activations-large tr").get();
    rows.sort(sortTableAttr);
    $.each(rows, function(index, row){
            $("#card-activations-large").append(row);
    });
    toggleSortState(cur_attr);
  });

  $("#user-title").on('click', function(){
    cur_attr = 'user-name';
    var rows = $("#card-activations-large tr").get();
    rows.sort(sortTableAttr);
    $.each(rows, function(index, row){
            $("#card-activations-large").append(row);
    });
    toggleSortState(cur_attr);
  });


  var multiselect_setup = function(){
    var lastChecked = null;
    var $chkboxes = $('#card-activations-large tr input[type="checkbox"]:visible');  
    $chkboxes.click(function(e) {
      if(!lastChecked) {
          lastChecked = this;
          return;
      }
      if(e.shiftKey) {
          var start = $chkboxes.index(this);
          var end = $chkboxes.index(lastChecked);
          $chkboxes.slice(Math.min(start,end), Math.max(start,end)+ 1).prop('checked', lastChecked.checked);
      }
      lastChecked = this;
    });
    
    $('#card-activations-large tr input[type="checkbox"]').on('click',function(){
      update_checkbox_count()
    })
  }
  multiselect_setup();
  $(document).ajaxComplete(function(event, request) {multiselect_setup();});


  // searches for workers. simple Fuse search.
  var filter = function() {
    // map through each card, hide it, and return a searchable obj.
    var searchable_cards = $('.card-activation').map(function() {
          $(this).hide(); // hide em all.
          $(':checkbox').prop('checked', false); //uncheck all of the boxes
          return { 
            sequence: $(this).data('sequence-number'), 
            last4:$(this).data('last-4'), 
            username:$(this).data('user-name'),
            sequsername:$(this).data('sequence-number') + ' ' + $(this).data('user-name'),
            obj: $(this)}
        })

    //small search area, so way less fuzzy
    var options = {
      keys: ['sequence', 'username','sequsername'],
      shouldSort: true,
      threshold: 0.1,
      location: 0
    };

    var fuse = new Fuse(searchable_cards, options);
    var query = $('#card-search').val();
    var found = [];
    if (query.length > 0) {
      found = fuse.search(query);
      // show only found workers.
      $(found).each(function(i, v) { $(v.obj).show();});
    } else {
      // show all of the workers, didn't find anything
      $('.card-activation').each(function(i, v) { $(v).show(); });
    }
  };
  

  //setup before functions
  var typingTimer;                //timer identifier
  var doneTypingInterval = 50;  //time in ms, 5 second for example
  var $input = $('#card-search');

  //on keyup, start the countdown
  $input.on('keyup', function () {
    clearTimeout(typingTimer);
    typingTimer = setTimeout(doneTyping, doneTypingInterval);
  });

  //on keydown, clear the countdown 
  $input.on('keydown', function () {
    clearTimeout(typingTimer);
  });

  //user is "finished typing," do something
  function doneTyping () {
    filter();
    if ($('#card-search').val() != '') {
      $('.form-control-clear button').removeClass('btn-secondary').addClass('btn-primary');
    } else {
      $('.form-control-clear button').removeClass('btn-primary').addClass('btn-secondary');
    }
    update_checkbox_count();
  }

  $('.form-control-clear').click(function() {
    $(this).siblings('input[type="text"]').val('').trigger('propertychange').focus();
    $('.form-control-clear button').removeClass('btn-primary').addClass('btn-secondary');
    $(this).siblings('input[type="text"]').blur();
    $('.card-activation').each(function(i, v) { $(v).show(); });
    update_checkbox_count()
  });
});
