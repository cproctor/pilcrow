filter = (option, mod_value, base_value, sel) ->
	if ( (option.value - (option.value % mod_value)) == base_value )
		$(sel).append $('<option>').text(option.text).val(option.value)
		
$ -> 
	if $('#isbn').length
		$('#isbn').first().focus()
	if $('.section#edit').length	
		options10 = []
		options1 = []
		$('#dewey10').find('option').each -> 
			options10.push { value: $(this).val(), text: $(this).text() }
		$('#dewey1').find('option').each -> 
			options1.push { value: $(this).val(), text: $(this).text() }
		
		$('#dewey100').change ->
			options = $('#dewey10').empty().data('options')
			filter(option, 100, Number($('#dewey100').val()), '#dewey10') for option in options10
			options = $('#dewey1').empty().data('options')
			filter(option, 100, Number($('#dewey100').val()), '#dewey1') for option in options1
		$('#dewey10').change ->
			options = $('#dewey1').empty().data('options')
			filter(option, 10, Number($('#dewey10').val()), '#dewey1') for option in options1

			
