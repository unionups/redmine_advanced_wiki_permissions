'use strict';
function ready() {
  document.body.addEventListener('ajax:complete', function() {
    $('#ajax-indicator').hide();
  });
  document.body.addEventListener('ajax:beforeSend', function() {
    // $('#ajax-indicator').show();
  });
}

document.addEventListener("DOMContentLoaded", ready);

// jquery.highlight
$.fn.highlight = function() {
  this.addClass("highlight");
    setTimeout( () => {
          this.removeClass('highlight');
    }, 2500);
};

// jquery.observe_field
$.fn.observe_field = function(frequency, callback) {

  frequency = frequency * 1000; // translate to milliseconds

  return this.each(function() {
    var $this = $(this);
    var prev = $this.val();
    var prevChecked = $this.prop('checked');

    var check = function() {
      if (removed()) {
        // if removed clear the interval and don't fire the callback
        if (ti)
          clearInterval(ti);
        return;
      }

      var val = $this.val();
      var checked = $this.prop('checked');
      if (prev != val || checked != prevChecked) {
        prev = val;
        prevChecked = checked;
        $this.map(callback); // invokes the callback on $this
      }
    };

    var removed = function() {
      return $this.closest('html').length == 0;
    };

    var reset = function() {
      if (ti) {
        clearInterval(ti);
        ti = setInterval(check, frequency);
      }
    };

    check();
    var ti = setInterval(check, frequency); // invoke check periodically

    // reset counter after user interaction
    $this.bind('keyup click mousemove', reset); // mousemove is for selects
  });
};

