//= require seamless/build/seamless.child.min.js
var people_ready;
people_ready = function() {
  if ($('#public-person-form').length != 0) {
    $("#new_person").validate({
    rules: {
      "person[first_name]": {
        required: true
      },
      "person[last_name]": {
        required: true
      },
      "person[email_address]": {
        email: true,
        require_from_group: [1, ".contact"]
      },
      "person[phone_number]": {
        phoneUS: true,
        require_from_group: [1, ".contact"]
      },
      "person[postal_code]":{
        zipcodeUS: true,
        required: true
      },
      'age_range':{
        required: true
      }
    }//,
    // errorPlacement: function(error, element) {
    //   error.appendTo( $("label:first") );
    // }
   });
  }
 };

// loading for turbolinks etc.
$(document).on('page:load turbolinks:load ready', people_ready);
