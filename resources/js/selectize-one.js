/**
 * selectize one select widget. Substitute the actual id of the widget for `{{widget_id}}`,
 * and the current value for {{widget_value}}.
 */
$('#{{widget_id}}').selectize({
  valueField: '{{key}}',
  labelField: '{{field}}',
  searchField: '{{field}}',
  hideSelected: false,
  create: false,

  load: function(query, callback) {
    if (query === null || !query.length || query.length < 5) return callback();
    $.ajax({
      url: '/json/auto/search-strings-{{entity}}?{{field}}=' + query,
      type: 'GET',
      dataType: 'json',
      error: function(xhr, status, error) {
        console.log( 'Query `' + query + '` failed with status: `' + status + '`; error: `' + error +'`');
        console.dir(xhr);
      },
      success: function(res) {
        callback(res);
      }
    });
  }
})[0].selectize.setValue('{{widget_value}}', true);
