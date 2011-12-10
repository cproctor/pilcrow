(function() {
  var filter;
  filter = function(option, mod_value, base_value, sel) {
    if ((option.value - (option.value % mod_value)) === base_value) {
      return $(sel).append($('<option>').text(option.text).val(option.value));
    }
  };
  $(function() {
    var options1, options10;
    if ($('#isbn').length) {
      $('#isbn').first().focus();
    }
    if ($('.section#edit').length) {
      options10 = [];
      options1 = [];
      $('#dewey10').find('option').each(function() {
        return options10.push({
          value: $(this).val(),
          text: $(this).text()
        });
      });
      $('#dewey1').find('option').each(function() {
        return options1.push({
          value: $(this).val(),
          text: $(this).text()
        });
      });
      $('#dewey100').change(function() {
        var option, options, _i, _j, _len, _len2, _results;
        options = $('#dewey10').empty().data('options');
        for (_i = 0, _len = options10.length; _i < _len; _i++) {
          option = options10[_i];
          filter(option, 100, Number($('#dewey100').val()), '#dewey10');
        }
        options = $('#dewey1').empty().data('options');
        _results = [];
        for (_j = 0, _len2 = options1.length; _j < _len2; _j++) {
          option = options1[_j];
          _results.push(filter(option, 100, Number($('#dewey100').val()), '#dewey1'));
        }
        return _results;
      });
      return $('#dewey10').change(function() {
        var option, options, _i, _len, _results;
        options = $('#dewey1').empty().data('options');
        _results = [];
        for (_i = 0, _len = options1.length; _i < _len; _i++) {
          option = options1[_i];
          _results.push(filter(option, 10, Number($('#dewey10').val()), '#dewey1'));
        }
        return _results;
      });
    }
  });
}).call(this);
