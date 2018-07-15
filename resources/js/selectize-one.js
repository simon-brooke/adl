/**
 * selectize one select widget. Substitute the actual id of the widget for `{{widget_id}}`,
 * and the current value for {{widget_value}}.
 */
$('#{{widget_id}}').selectize({
  valueField: 'id',
  labelField: 'name',
  searchField: 'name',
  hideSelected: false,
  create: false,

  load: function(query, callback) {
    console.log('Desperately seeking ' + query);
    if (query === null || !query.length) return callback();
    $.ajax({
      url: '/json/auto/search-strings-electors?name=' + query,
      type: 'GET',
      dataType: 'jsonp',
      error: function() {
        console.log( 'Query ' + query + ' failed.');
        callback();
      },
      success: function(res) {
        console.log('Received ' + res + ' records for ' + query);
        callback(res);
      }
    });
  }
})[0].selectize.setValue({{widget_value}}, true);
