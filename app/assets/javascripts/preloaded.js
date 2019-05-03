$(document).on('turbolinks:load',function() {

  function filterPreloaded(){
    
    var low = $('#low_seq').val();
    var high = $('#high_seq').val();
    
    var low_int = !isNaN(low) && low !== '' ;
    var high_int = !isNaN(high) && high !== '';
    
    var optionSelected = $('#preload-user-filter option:selected').text();
    var valueSelected = $('#preload-user-filter option:selected').val();
    var batch = $('#batch-id-filter option:selected').text();

    $('.gift-card').show(); // show em all

    if (batch == 'All Batches'|| batch == '' ) {
      console.log('no user filter');
    }else{
      $('.gift-card').each(function() {
        console.log($(this).data("batch-id"))
         if ($(this).data("batch-id") != parseInt(batch)) {
          $(this).hide()
         }
      });
    }
    if (optionSelected == 'All Users'|| optionSelected == '' ) {
      console.log('no user filter');
    }else{
      $('.gift-card').each(function() {
         if ($(this).data("user-id") != valueSelected) {
          $(this).hide()
         }
      });
    }

    if ( !low_int && !high_int) {
      console.log('no numbers');
      //if high & low are NAN, show all;
      // no-op
    }else if (high_int && !low_int) {
    
      // if high is a number, hide all above high
      $('.gift-card').each(function() {

         if (parseInt($(this).data("sequence-number")) > high) {
          $(this).hide()
         }
      });
    }else if (low_int && !high_int) {
    
      // if low is a number, hide all below low  
      $('.gift-card').each(function() {
         if (parseInt($(this).data("sequence-number")) < low) {
          $(this).hide()
         }
      });
    }else if (high_int && low_int) {
      $('.gift-card').each(function() {
         if (parseInt($(this).data("sequence-number")) < low) {
          $(this).hide()
         }
      });
      $('.gift-card').each(function() {
         if (parseInt($(this).data("sequence-number")) > high) {
          $(this).hide()
         }
      });
    }
  }
    
  $('#preload-user-filter').change(function(){
    filterPreloaded();
  });

  $('.preload-filter').change(function(){
    filterPreloaded();
  });

   $('#batch-id-filter').change(function(){
    filterPreloaded();
  });


});
